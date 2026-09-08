import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/driver_finance/data/mappers/driver_financial_movement_mapper.dart';
import 'package:horus_system/features/driver_finance/data/models/driver_financial_movement_model.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_type.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('DriverFinancialMovementMapper', () {
    test('encodes movement date without timezone conversion', () {
      final data = DriverFinancialMovementWriteData(
        companyId: 'company-1',
        driverId: 'driver-1',
        tripId: 'trip-1',
        type: DriverFinancialMovementType.driverCharge,
        amount: 125.5,
        movementDate: BusinessDate(year: 2026, month: 8, day: 23),
        notes: 'note',
      );

      final insert = data.toInsertMap();
      final update = data.toUpdateMap();

      expect(insert['movement_date'], '2026-08-23');
      expect(update['movement_date'], '2026-08-23');
      expect(update.containsKey('updated_at'), isFalse);
    });

    test('writes canonical date and UTC timestamps to audit values', () {
      final model = DriverFinancialMovementModel(
        id: 'movement-1',
        companyId: 'company-1',
        driverId: 'driver-1',
        tripId: 'trip-1',
        type: DriverFinancialMovementType.driverCharge,
        amount: 125.5,
        movementDate: BusinessDate(year: 2026, month: 8, day: 23),
        notes: 'note',
        createdAt: DateTime.utc(2026, 8, 23, 9),
        updatedAt: DateTime.utc(2026, 8, 23, 10),
      );

      final audit = model.toAuditValues();

      expect(audit['movement_date'], '2026-08-23');
      expect(audit['created_at'], '2026-08-23T09:00:00.000Z');
      expect(audit['updated_at'], '2026-08-23T10:00:00.000Z');
    });

    test('maps BusinessDate entity boundary without substitution', () {
      final movementDate = BusinessDate(year: 2026, month: 8, day: 23);
      final model = DriverFinancialMovementModel(
        id: 'movement-1',
        companyId: 'company-1',
        driverId: 'driver-1',
        type: DriverFinancialMovementType.advance,
        amount: 100,
        movementDate: movementDate,
      );

      final entity = model.toEntity();

      expect(entity.movementDate, same(movementDate));
    });
  });
}
