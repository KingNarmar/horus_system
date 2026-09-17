import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/usecases/get_company_business_date_usecase.dart';
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
    test('forwards exact business-date boundaries', () async {
      final repository = _FakeDriverBalanceRepository(
        balance: _balance(closingBalance: -5600),
      );
      final useCase = GetCanonicalDriverBalanceUseCase(repository);
      final beforeExclusive = BusinessDate(year: 2026, month: 7, day: 23);
      final checkpointBeforeExclusive = BusinessDate(
        year: 2026,
        month: 9,
        day: 1,
      );

      final result = await useCase(
        GetCanonicalDriverBalanceParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          driverId: '  $_driverId  ',
          beforeExclusive: beforeExclusive,
          checkpointBeforeExclusive: checkpointBeforeExclusive,
        ),
      );

      expect(result, isA<Success<DriverBalance>>());
      expect(result.dataOrNull?.netBalance, -5600);
      expect(repository.balanceCalls, 1);
      expect(repository.lastCompanyId, _companyId);
      expect(repository.lastDriverId, _driverId);
      expect(repository.lastBeforeExclusive, beforeExclusive);
      expect(
        repository.lastCheckpointBeforeExclusive,
        checkpointBeforeExclusive,
      );
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
          beforeExclusive: BusinessDate(year: 2026, month: 9, day: 3),
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
          beforeExclusive: BusinessDate(year: 2026, month: 9, day: 2),
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
          beforeExclusive: BusinessDate(year: 2026, month: 9, day: 2),
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

  group('GetCurrentCanonicalDriverBalanceUseCase', () {
    test(
      'uses trusted company date and exclusive next business date',
      () async {
        final provider = _FakeCompanyBusinessDateProvider(
          Success(BusinessDate(year: 2026, month: 9, day: 8)),
        );
        final repository = _FakeDriverBalanceRepository(
          balance: _balance(closingBalance: -5600),
        );
        final useCase = GetCurrentCanonicalDriverBalanceUseCase(
          getCompanyBusinessDateUseCase: GetCompanyBusinessDateUseCase(
            provider,
          ),
          getCanonicalDriverBalanceUseCase: GetCanonicalDriverBalanceUseCase(
            repository,
          ),
        );

        final result = await useCase(
          GetCurrentCanonicalDriverBalanceParams(
            currentCompanyContext: _context(CompanyRole.accountant),
            driverId: _driverId,
          ),
        );

        expect(result, isA<Success<DriverBalance>>());
        expect(provider.calls, 1);
        expect(provider.lastCompanyId, _companyId);
        expect(
          repository.lastBeforeExclusive,
          BusinessDate(year: 2026, month: 9, day: 9),
        );
        expect(repository.lastCheckpointBeforeExclusive, isNull);
      },
    );

    test(
      'does not query balance when trusted business-date lookup fails',
      () async {
        const failure = ServerFailure(code: FailureCodes.serverError);
        final provider = _FakeCompanyBusinessDateProvider(
          const FailureResult<BusinessDate>(failure),
        );
        final repository = _FakeDriverBalanceRepository();
        final useCase = GetCurrentCanonicalDriverBalanceUseCase(
          getCompanyBusinessDateUseCase: GetCompanyBusinessDateUseCase(
            provider,
          ),
          getCanonicalDriverBalanceUseCase: GetCanonicalDriverBalanceUseCase(
            repository,
          ),
        );

        final result = await useCase(
          GetCurrentCanonicalDriverBalanceParams(
            currentCompanyContext: _context(CompanyRole.accountant),
            driverId: _driverId,
          ),
        );

        expect(result, isA<FailureResult<DriverBalance>>());
        expect(result.failureOrNull, same(failure));
        expect(repository.balanceCalls, 0);
      },
    );
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
    periodEnd: BusinessDate(year: 2026, month: 8, day: 31),
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
  BusinessDate? lastBeforeExclusive;
  BusinessDate? lastCheckpointBeforeExclusive;

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
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  }) async {
    balanceCalls++;
    lastCompanyId = companyId;
    lastDriverId = driverId;
    lastBeforeExclusive = beforeExclusive;
    lastCheckpointBeforeExclusive = checkpointBeforeExclusive;
    return Success(balance);
  }
}

class _FakeCompanyBusinessDateProvider implements CompanyBusinessDateProvider {
  final Result<BusinessDate> result;
  int calls = 0;
  String? lastCompanyId;

  _FakeCompanyBusinessDateProvider(this.result);

  @override
  Future<Result<BusinessDate>> getBusinessDate({
    required String companyId,
  }) async {
    calls++;
    lastCompanyId = companyId;
    return result;
  }
}
