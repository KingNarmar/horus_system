import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/driver_finance/data/datasources/canonical_driver_balance_remote_data_source.dart';
import 'package:horus_system/features/driver_finance/data/repositories/driver_balance_activity_repository_impl.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance_activity.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_money_balance.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  final currency = CurrencyCode.tryParse('AED')!;

  test('passes tenant, driver, currency and checkpoint boundary to source', () async {
    final remote = _FakeRemote();
    final repo = DriverBalanceActivityRepositoryImpl(remoteDataSource: remote);
    final before = BusinessDate(year: 2026, month: 10, day: 23);
    final checkpointBefore = BusinessDate(year: 2026, month: 9, day: 1);
    final result = await repo.getDriverBalanceActivity(
      companyId: 'company-1',
      driverId: 'driver-1',
      currency: currency,
      currencyFractionDigits: 2,
      beforeExclusive: before,
      checkpointBeforeExclusive: checkpointBefore,
    );

    expect(result, isA<Success<DriverBalanceActivity>>());
    expect(remote.companyId, 'company-1');
    expect(remote.driverId, 'driver-1');
    expect(remote.currencyCode, 'AED');
    expect(remote.fractionDigits, 2);
    expect(remote.beforeExclusive, before);
    expect(remote.checkpointBeforeExclusive, checkpointBefore);
    expect(result.dataOrNull?.entries, isEmpty);
  });

  test('sanitizes denied database reads to finance permission failures', () async {
    final remote = _FakeRemote(
      error: const PostgrestException(
        message: 'confidential backend error',
        code: '42501',
      ),
    );
    final repo = DriverBalanceActivityRepositoryImpl(remoteDataSource: remote);
    final result = await repo.getDriverBalanceActivity(
      companyId: 'company-1',
      driverId: 'driver-1',
      currency: currency,
      currencyFractionDigits: 2,
      beforeExclusive: BusinessDate(year: 2026, month: 10, day: 23),
    );

    expect(result, isA<FailureResult<DriverBalanceActivity>>());
    expect(result.failureOrNull, isA<PermissionFailure>());
    expect(result.failureOrNull?.code, FailureCodes.permissionDriverFinanceView);
    expect(result.failureOrNull?.message, isNull);
  });
}

final class _FakeRemote implements DriverBalanceActivityRemoteDataSource {
  final Object? error;
  String? companyId;
  String? driverId;
  String? currencyCode;
  int? fractionDigits;
  BusinessDate? beforeExclusive;
  BusinessDate? checkpointBeforeExclusive;

  _FakeRemote({this.error});

  @override
  Future<DriverBalanceActivity> getDriverBalanceActivity({
    required String companyId,
    required String driverId,
    required String currencyCode,
    required int currencyFractionDigits,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  }) async {
    if (error != null) throw error!;
    this.companyId = companyId;
    this.driverId = driverId;
    this.currencyCode = currencyCode;
    fractionDigits = currencyFractionDigits;
    this.beforeExclusive = beforeExclusive;
    this.checkpointBeforeExclusive = checkpointBeforeExclusive;
    final currency = CurrencyCode.tryParse(currencyCode)!;
    final zero = Money(minorUnits: 0, currency: currency);
    return DriverBalanceActivity(
      canonicalBalance: DriverMoneyBalance(
        companyId: companyId,
        driverId: driverId,
        currency: currency,
        currencyFractionDigits: currencyFractionDigits,
        totalAdvances: zero,
        totalDriverCharges: zero,
        totalTripExpenseCredits: zero,
        totalCashReturns: zero,
      ),
      entries: const [],
    );
  }
}
