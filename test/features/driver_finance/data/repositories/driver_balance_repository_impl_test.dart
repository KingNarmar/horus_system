import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/driver_finance/data/datasources/canonical_driver_balance_remote_data_source.dart';
import 'package:horus_system/features/driver_finance/data/models/driver_balance_model.dart';
import 'package:horus_system/features/driver_finance/data/repositories/driver_balance_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('DriverBalanceRepositoryImpl', () {
    test('maps and forwards independent balance boundaries', () async {
      final remoteDataSource = _FakeCanonicalBalanceRemoteDataSource(
        balanceModel: _balanceModel(),
      );
      final repository = DriverBalanceRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );
      final beforeExclusive = DateTime(2026, 7, 23);
      final checkpointBeforeExclusive = DateTime(2026, 9, 1);

      final result = await repository.getCanonicalDriverBalance(
        companyId: _companyId,
        driverId: _driverId,
        beforeExclusive: beforeExclusive,
        checkpointBeforeExclusive: checkpointBeforeExclusive,
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.checkpoint?.settlementId, 'settlement-1');
      expect(result.dataOrNull?.netBalance, -5625);
      expect(remoteDataSource.balanceCalls, 1);
      expect(remoteDataSource.lastCompanyId, _companyId);
      expect(remoteDataSource.lastDriverId, _driverId);
      expect(remoteDataSource.lastBeforeExclusive, beforeExclusive);
      expect(
        remoteDataSource.lastCheckpointBeforeExclusive,
        checkpointBeforeExclusive,
      );
    });

    test('maps 42501 to Driver Finance view permission failure', () async {
      final remoteDataSource = _FakeCanonicalBalanceRemoteDataSource(
        error: const PostgrestException(
          message: 'permission denied',
          code: '42501',
        ),
      );
      final repository = DriverBalanceRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );

      final result = await repository.getCanonicalDriverBalance(
        companyId: _companyId,
        driverId: _driverId,
        beforeExclusive: DateTime(2026, 7, 23),
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionDriverFinanceView,
      );
      expect(
        result.failureOrNull?.message,
        'Driver finance access is not allowed.',
      );
    });

    test('maps other Postgrest errors to server failure', () async {
      final remoteDataSource = _FakeCanonicalBalanceRemoteDataSource(
        error: const PostgrestException(
          message: 'database unavailable',
          code: 'PGRST500',
        ),
      );
      final repository = DriverBalanceRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );

      final result = await repository.getCanonicalDriverBalance(
        companyId: _companyId,
        driverId: _driverId,
        beforeExclusive: DateTime(2026, 7, 23),
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, 'PGRST500');
      expect(result.failureOrNull?.message, 'database unavailable');
    });

    test('maps unexpected errors without changing their text', () async {
      final remoteDataSource = _FakeCanonicalBalanceRemoteDataSource(
        error: Exception('unexpected balance failure'),
      );
      final repository = DriverBalanceRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );

      final result = await repository.getCanonicalDriverBalance(
        companyId: _companyId,
        driverId: _driverId,
        beforeExclusive: DateTime(2026, 7, 23),
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(
        result.failureOrNull?.message,
        'Exception: unexpected balance failure',
      );
    });
  });
}

const _companyId = 'company-1';
const _driverId = 'driver-1';

DriverBalanceModel _balanceModel() {
  return DriverBalanceModel(
    companyId: _companyId,
    driverId: _driverId,
    checkpointSettlementId: 'settlement-1',
    checkpointPeriodEnd: DateTime(2026, 8, 31),
    checkpointSnapshotCreatedAt: DateTime.utc(2026, 9, 1, 8),
    checkpointClosingBalance: -5600,
    totalAdvances: 100,
    totalDriverCharges: 50,
    totalTripExpenseCredits: 100,
    totalCashReturns: 25,
  );
}

class _FakeCanonicalBalanceRemoteDataSource
    implements CanonicalDriverBalanceRemoteDataSource {
  final DriverBalanceModel? balanceModel;
  final Object? error;
  int balanceCalls = 0;
  String? lastCompanyId;
  String? lastDriverId;
  DateTime? lastBeforeExclusive;
  DateTime? lastCheckpointBeforeExclusive;

  _FakeCanonicalBalanceRemoteDataSource({this.balanceModel, this.error});

  @override
  Future<DriverBalanceModel> getCanonicalDriverBalance({
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
    if (error != null) throw error!;
    return balanceModel ?? _balanceModel();
  }
}
