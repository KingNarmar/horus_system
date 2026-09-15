import 'package:horus_system/features/expenses/domain/entities/expense_attribution.dart';
import 'package:horus_system/features/expenses/domain/policies/expense_attribution_policy.dart';
import 'package:test/test.dart';

void main() {
  group('ExpenseAttributionPolicy', () {
    test('allows general expenses without attribution', () {
      expect(
        ExpenseAttributionPolicy.isAllowed(const ExpenseAttribution()),
        isTrue,
      );
    });

    test('allows standalone driver and vehicle attribution combinations', () {
      const attribution = ExpenseAttribution(
        driverId: 'driver-1',
        tractorHeadId: 'tractor-1',
        trailerId: 'trailer-1',
      );

      expect(ExpenseAttributionPolicy.isAllowed(attribution), isTrue);
    });

    test('allows trip as the sole canonical attribution', () {
      expect(
        ExpenseAttributionPolicy.isAllowed(
          const ExpenseAttribution(tripId: 'trip-1'),
        ),
        isTrue,
      );
    });

    test('rejects trip combined with direct asset attribution', () {
      const attribution = ExpenseAttribution(
        tripId: 'trip-1',
        driverId: 'driver-1',
      );

      expect(ExpenseAttributionPolicy.isAllowed(attribution), isFalse);
    });
  });
}
