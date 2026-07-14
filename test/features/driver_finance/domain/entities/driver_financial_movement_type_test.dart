import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_type.dart';
import 'package:test/test.dart';

void main() {
  group('DriverFinancialMovementType', () {
    test('serializes explicit persistence values', () {
      expect(DriverFinancialMovementType.advance.value, 'advance');
      expect(DriverFinancialMovementType.driverCharge.value, 'driver_charge');
      expect(DriverFinancialMovementType.cashReturn.value, 'cash_return');
    });

    test('parses explicit persistence values', () {
      expect(
        driverFinancialMovementTypeFromValue('advance'),
        DriverFinancialMovementType.advance,
      );
      expect(
        driverFinancialMovementTypeFromValue('driver_charge'),
        DriverFinancialMovementType.driverCharge,
      );
      expect(
        driverFinancialMovementTypeFromValue('cash_return'),
        DriverFinancialMovementType.cashReturn,
      );
    });

    test('preserves legacy deduction audit and data compatibility', () {
      expect(
        driverFinancialMovementTypeFromValue('deduction'),
        DriverFinancialMovementType.driverCharge,
      );
    });

    test('only driver charges may link to trips', () {
      expect(DriverFinancialMovementType.advance.canLinkTrip, isFalse);
      expect(DriverFinancialMovementType.driverCharge.canLinkTrip, isTrue);
      expect(DriverFinancialMovementType.cashReturn.canLinkTrip, isFalse);
    });
  });
}
