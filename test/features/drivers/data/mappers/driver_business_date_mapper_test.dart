import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/drivers/data/mappers/driver_mapper.dart';
import 'package:horus_system/features/drivers/data/models/driver_model.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('Driver business-date mapping', () {
    test('model preserves license expiry calendar date', () {
      final model = DriverModel.fromMap({
        'id': 'driver-1',
        'company_id': 'company-1',
        'full_name': 'Driver One',
        'license_expiry_date': '2026-09-07',
        'is_active': true,
      });

      expect(
        model.licenseExpiryDate,
        BusinessDate(year: 2026, month: 9, day: 7),
      );
      expect(model.toEntity().licenseExpiryDate, model.licenseExpiryDate);
    });

    test('write data serializes exact date without timezone conversion', () {
      final data = DriverWriteData(
        companyId: 'company-1',
        fullName: 'Driver One',
        licenseExpiryDate: BusinessDate(year: 2026, month: 9, day: 7),
      );

      final map = data.toInsertMap();

      expect(map['license_expiry_date'], '2026-09-07');
    });

    test('model rejects timestamp-shaped license expiry date', () {
      expect(
        () => DriverModel.fromMap({
          'id': 'driver-1',
          'company_id': 'company-1',
          'full_name': 'Driver One',
          'license_expiry_date': '2026-09-07T00:00:00Z',
          'is_active': true,
        }),
        throwsFormatException,
      );
    });
  });
}
