import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance_activity_entry.dart';
import 'package:test/test.dart';

void main() {
  final currency = CurrencyCode.tryParse('AED')!;

  group('DriverBalanceActivityEntry', () {
    for (final kind in [
      DriverBalanceActivityKind.advance,
      DriverBalanceActivityKind.driverCharge,
      DriverBalanceActivityKind.cashReturn,
      DriverBalanceActivityKind.driverPaidTripExpense,
    ]) {
      test('maps signed balance impact for $kind without rounding', () {
        final entry = DriverBalanceActivityEntry(
          source: kind == DriverBalanceActivityKind.driverPaidTripExpense
              ? DriverBalanceActivitySource.tripExpense
              : DriverBalanceActivitySource.financialMovement,
          sourceId: 'source-1',
          kind: kind,
          companyId: 'company-1',
          driverId: 'driver-1',
          businessDate: BusinessDate(year: 2026, month: 10, day: 21),
          createdAt: DateTime.utc(2026, 10, 21),
          amount: Money(minorUnits: 12345, currency: currency),
        );

        final negative =
            kind == DriverBalanceActivityKind.advance ||
            kind == DriverBalanceActivityKind.driverCharge;
        expect(entry.balanceImpact.minorUnits, negative ? -12345 : 12345);
        expect(entry.balanceImpact.currency, currency);
      });
    }

    test(
      'different financial sources with equal IDs remain distinguishable',
      () {
        DriverBalanceActivityEntry make(DriverBalanceActivitySource source) =>
            DriverBalanceActivityEntry(
              source: source,
              sourceId: 'same-id',
              kind: source == DriverBalanceActivitySource.tripExpense
                  ? DriverBalanceActivityKind.driverPaidTripExpense
                  : DriverBalanceActivityKind.advance,
              companyId: 'company-1',
              driverId: 'driver-1',
              businessDate: BusinessDate(year: 2026, month: 10, day: 21),
              createdAt: DateTime.utc(2026, 10, 21),
              amount: Money(minorUnits: 1, currency: currency),
            );

        expect(
          make(DriverBalanceActivitySource.financialMovement).stableId,
          isNot(make(DriverBalanceActivitySource.tripExpense).stableId),
        );
      },
    );
  });
}
