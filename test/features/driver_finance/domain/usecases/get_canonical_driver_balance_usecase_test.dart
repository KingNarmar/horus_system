import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance_checkpoint.dart';
import 'package:horus_system/features/driver_finance/domain/repositories/driver_balance_repository.dart';
import 'package:horus_system/features/driver_finance/domain/usecases/get_canonical_driver_balance_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('GetCanonicalDriverBalanceUseCase', () {
    test('uses latest finalized checkpoint for the current balance', () async {
      final repository = _FakeDriverBalanceRepository(
        balance: _balance(closingBalance: -5600),
      );
      final useCase = GetCanonicalDriverBalanceUseCase(repository);

      final result = await useCase(
        GetCanonicalDriverBalanceParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          driverId: '  $_driverId  ',
          beforeExclusive: DateTime(2026, 7, 23, 15),
        ),
      );

      expect(result, isA<Success<DriverBalance>>());
      expect(result.dataOrNull?.netBalance, -5600);
      expect(repository.balanceCalls, 1);
      expect(repository.lastCompanyId, _companyId);
      expect(repository.lastDriverId, _driverId);
      expect(repository.lastBeforeExclusive, DateTime(2026, 7, 23));
      expect(repository.lastCheckpointBeforeExclusive, isNull);
    });

    test('normalizes a bounded settlement checkpoint date', () async {
      final repository = _FakeDriverBalanceRepository(
        balance: _balance(closingBalance: -5600),
      );
      final useCase = GetCanonicalDriverBalanceUseCase(repository);

      await useCase(
        GetCanonicalDriverBalanceParams(
          currentCompanyContext: _context(CompanyRole.owner),
          driverId: _driverId,
          beforeExclusive: DateTime(2026, 9, 1, 18),
          checkpointBeforeExclusive: DateTime(2026, 9, 1, 9),
        ),
      );

      expect(repository.lastBeforeExclusive, DateTime(2026, 9, 1));
      expect(repository.lastCheckpointBeforeExclusive, DateTime(2026, 9, 1));
    });

    test('preserves post-checkpoint financial effects', () async {
      final repository = _FakeDriverBalanceRepository(
        balance: DriverBalance(
          companyId: _companyId,
          driverId: _driverId,
          checkpoint: _checkpoint(-5600),
          totalAdvances: 100,
          totalDriverCharges: 50,
          totalTripExpenseCredits: 100,
          totalCashReturns: 25,
        ),
      );
      final useCase = GetCanonicalDriverBalanceUseCase(repository);

      final result = await useCase(
        GetCanonicalDriverBalanceParams(
          currentCompanyContext: _context(CompanyRole.owner),
          driverId: _driverId,
          beforeExclusive: DateTime(2026, 9, 3),
        ),
      );

      expect(result.dataOrNull?.netBalance, -5625);
    });

    test('blocks driver role before repository access', () async {
      final repository = _FakeDriverBalanceRepository();
      final useCase = GetCanonicalDriverBalanceUseCase(repository);

      final result = await useCase(
        GetCanonicalDriverBalanceParams(
          currentCompanyContext: _context(CompanyRole.driver),
          driverId: _driverId,
          beforeExclusive: DateTime(2026, 9, 2),
        ),
      );

      expect(result, isA<FailureResult<DriverBalance>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionDriverFinanceView,
      );
      expect(repository.balanceCalls, 0);
    });

    test('requires a driver id before repository access', () async {
      final repository = _FakeDriverBalanceRepository();
      final useCase = GetCanonicalDriverBalanceUseCase(repository);

      final result = await useCase(
        GetCanonicalDriverBalanceParams(
          currentCompanyContext: _context(CompanyRole.viewer),
          driverId: '  ',
          beforeExclusive: DateTime(2026, 9, 2),
        ),
      );

      expect(result, isA<FailureResult<DriverBalance>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationDriverIdRequired,
      );
      expect(repository.balanceCalls, 0);
    });
  });
}

const _companyId = 'company-1';
const _driverId = 'driver-1';

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(id: _companyId, name: 'Company'),
    role: role,
  );
}

DriverBalanceCheckpoint _checkpoint(double closingBalance) {
  return DriverBalanceCheckpoint(
    settlementId: 'settlement-1',
    periodEnd: DateTime(2026, 8, 31),
    snapshotCreatedAt: DateTime.utc(2026, 9, 1, 8),
    closingBalance: closingBalance,
  );
}

DriverBalance _balance({required double closingBalance}) {
  return DriverBalance(
    companyId: _companyId,
    driverId: _driverId,
    checkpoint: _checkpoint(closingBalance),
    totalAdvances: 0,
    totalDriverCharges: 0,
  );
}

class _FakeDriverBalanceRepository implements DriverBalanceRepository {
  final DriverBalance balance;
  int balanceCalls = 0;
  String? lastCompanyId;
  String? lastDriverId;
  DateTime? lastBeforeExclusive;
  DateTime? lastCheckpointBeforeExclusive;

  _FakeDriverBalanceRepository({DriverBalance? balance})
    : balance =
          balance ??
          const DriverBalance(
            companyId: _companyId,
            driverId: _driverId,
            totalAdvances: 0,
            totalDriverCharges: 0,
          );

  @override
  Future<Result<DriverBalance>> getCanonicalDriverBalance({
    required String companyId,
    required String driverId,
    required DateTime beforeExclusive,
    DateTime? checkpointBeforeExclusive,
  }) async {
    balanceCalls++;
    lastCompanyId = companyId;
    lastDriverId = driverId;
    lastBeforeExclusive = beforeExclusive;
    lastCheckpointBeforeExclusive = checkpointBeforeExclusive;
    return Success(balance);
  }
}
