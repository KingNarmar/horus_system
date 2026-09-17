import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/driver_finance/data/datasources/canonical_driver_balance_remote_data_source.dart';
import 'package:horus_system/features/driver_finance/data/models/driver_balance_model.dart';
import 'package:horus_system/features/driver_finance/data/models/driver_money_balance_model.dart';
import 'package:horus_system/features/driver_finance/data/repositories/driver_balance_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('DriverBalanceRepositoryImpl', () {
    test('maps and forwards independent business-date boundaries', () async {
      final remoteDataSource = _FakeCanonicalBalanceRemoteDataSource(
        balanceModel: _balanceModel(),
      );
      final repository = DriverBalanceRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );
      final beforeExclusive = BusinessDate(year: 2026, month: 7, day: 23);
      final checkpointBeforeExclusive = BusinessDate(
        year: 2026,
        month: 9,
        day: 1,
      );

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

    test('maps exact canonical money balance without precision loss', () async {
      final remoteDataSource = _FakeCanonicalBalanceRemoteDataSource(
        moneyBalanceModel: _moneyBalanceModel(),
      );
      final repository = DriverBalanceRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );
      final currency = CurrencyCode.tryParse('KWD')!;
      final beforeExclusive = BusinessDate(year: 2026, month: 9, day: 17);

      final result = await repository.getCanonicalDriverMoneyBalance(
        companyId: _companyId,
        driverId: _driverId,
        currency: currency,
        currencyFractionDigits: 3,
        beforeExclusive: beforeExclusive,
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.currency.value, 'KWD');
      expect(result.dataOrNull?.currencyFractionDigits, 3);
      expect(result.dataOrNull?.netBalance.minorUnits, -5625001);
      expect(remoteDataSource.moneyBalanceCalls, 1);
      expect(remoteDataSource.lastCurrencyCode, 'KWD');
      expect(remoteDataSource.lastCurrencyFractionDigits, 3);
      expect(remoteDataSource.lastBeforeExclusive, beforeExclusive);
    });

    test('sanitizes 42501 to Driver Finance view permission failure', () async {
      final beforeExclusive = BusinessDate(year: 2026, month: 7, day: 23);
      final checkpointBeforeExclusive = BusinessDate(
        year: 2026,
        month: 9,
        day: 1,
      );
      final remoteDataSource = _FakeCanonicalBalanceRemoteDataSource(
        error: const PostgrestException(
          message: 'permission denied',
          code: '42501',
          details: 'backend details',
          hint: 'backend hint',
        ),
      );
      final repository = DriverBalanceRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );

      final result = await repository.getCanonicalDriverBalance(
        companyId: _companyId,
        driverId: _driverId,
        beforeExclusive: beforeExclusive,
        checkpointBeforeExclusive: checkpointBeforeExclusive,
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionDriverFinanceView,
      );
      expect(result.failureOrNull?.message, isNull);
      expect(remoteDataSource.balanceCalls, 1);
      expect(remoteDataSource.lastCompanyId, _companyId);
      expect(remoteDataSource.lastDriverId, _driverId);
      expect(remoteDataSource.lastBeforeExclusive, beforeExclusive);
      expect(
        remoteDataSource.lastCheckpointBeforeExclusive,
        checkpointBeforeExclusive,
      );
    });

    test('sanitizes other Postgrest errors to server failure', () async {
      final remoteDataSource = _FakeCanonicalBalanceRemoteDataSource(
        error: const PostgrestException(
          message: 'database unavailable',
          code: 'PGRST500',
          details: 'backend details',
          hint: 'backend hint',
        ),
      );
      final repository = DriverBalanceRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );

      final result = await repository.getCanonicalDriverBalance(
        companyId: _companyId,
        driverId: _driverId,
        beforeExclusive: BusinessDate(year: 2026, month: 7, day: 23),
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('sanitizes unexpected errors', () async {
      final remoteDataSource = _FakeCanonicalBalanceRemoteDataSource(
        error: Exception('unexpected balance failure'),
      );
      final repository = DriverBalanceRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );

      final result = await repository.getCanonicalDriverBalance(
        companyId: _companyId,
        driverId: _driverId,
        beforeExclusive: BusinessDate(year: 2026, month: 7, day: 23),
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('sanitizes model-to-entity mapping failure inside boundary', () async {
      final remoteDataSource = _FakeCanonicalBalanceRemoteDataSource(
        balanceModel: _invalidCheckpointModel(),
      );
      final repository = DriverBalanceRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );

      final result = await repository.getCanonicalDriverBalance(
        companyId: _companyId,
        driverId: _driverId,
        beforeExclusive: BusinessDate(year: 2026, month: 7, day: 23),
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
      expect(remoteDataSource.balanceCalls, 1);
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
    checkpointPeriodEnd: BusinessDate(year: 2026, month: 8, day: 31),
    checkpointSnapshotCreatedAt: DateTime.utc(2026, 9, 1, 8),
    checkpointClosingBalance: -5600,
    totalAdvances: 100,
    totalDriverCharges: 50,
    totalTripExpenseCredits: 100,
    totalCashReturns: 25,
  );
}

DriverMoneyBalanceModel _moneyBalanceModel() {
  return DriverMoneyBalanceModel(
    companyId: _companyId,
    driverId: _driverId,
    currencyCode: 'KWD',
    currencyFractionDigits: 3,
    checkpointSettlementId: 'settlement-1',
    checkpointPeriodEnd: BusinessDate(year: 2026, month: 8, day: 31),
    checkpointSnapshotCreatedAt: DateTime.utc(2026, 9, 1, 8),
    checkpointClosingBalanceMinorUnits: -5600000,
    totalAdvancesMinorUnits: 100001,
    totalDriverChargesMinorUnits: 50000,
    totalTripExpenseCreditsMinorUnits: 100000,
    totalCashReturnsMinorUnits: 25000,
  );
}

DriverBalanceModel _invalidCheckpointModel() {
  return const DriverBalanceModel(
    companyId: _companyId,
    driverId: _driverId,
    checkpointSettlementId: 'settlement-1',
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
  final DriverMoneyBalanceModel? moneyBalanceModel;
  final Object? error;
  int balanceCalls = 0;
  int moneyBalanceCalls = 0;
  String? lastCompanyId;
  String? lastDriverId;
  String? lastCurrencyCode;
  int? lastCurrencyFractionDigits;
  BusinessDate? lastBeforeExclusive;
  BusinessDate? lastCheckpointBeforeExclusive;

  _FakeCanonicalBalanceRemoteDataSource({
    this.balanceModel,
    this.moneyBalanceModel,
    this.error,
  });

  @override
  Future<DriverBalanceModel> getCanonicalDriverBalance({
    required String companyId,
    required String driverId,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  }) async {
    balanceCalls++;
    _captureCommon(
      companyId: companyId,
      driverId: driverId,
      beforeExclusive: beforeExclusive,
      checkpointBeforeExclusive: checkpointBeforeExclusive,
    );
    if (error != null) throw error!;
    return balanceModel ?? _balanceModel();
  }

  @override
  Future<DriverMoneyBalanceModel> getCanonicalDriverMoneyBalance({
    required String companyId,
    required String driverId,
    required String currencyCode,
    required int currencyFractionDigits,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  }) async {
    moneyBalanceCalls++;
    lastCurrencyCode = currencyCode;
    lastCurrencyFractionDigits = currencyFractionDigits;
    _captureCommon(
      companyId: companyId,
      driverId: driverId,
      beforeExclusive: beforeExclusive,
      checkpointBeforeExclusive: checkpointBeforeExclusive,
    );
    if (error != null) throw error!;
    return moneyBalanceModel ?? _moneyBalanceModel();
  }

  void _captureCommon({
    required String companyId,
    required String driverId,
    required BusinessDate beforeExclusive,
    required BusinessDate? checkpointBeforeExclusive,
  }) {
    lastCompanyId = companyId;
    lastDriverId = driverId;
    lastBeforeExclusive = beforeExclusive;
    lastCheckpointBeforeExclusive = checkpointBeforeExclusive;
  }
}
