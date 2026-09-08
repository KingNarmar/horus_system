import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/fleet/data/mappers/tractor_mapper.dart';
import 'package:horus_system/features/fleet/data/mappers/trailers_mapper.dart';
import 'package:horus_system/features/fleet/data/models/tractor_head_model.dart';
import 'package:horus_system/features/fleet/data/models/trailer_model.dart';
import 'package:horus_system/features/fleet/domain/entities/tractor_head_write_data.dart';
import 'package:horus_system/features/fleet/domain/entities/trailer_write_data.dart';
import 'package:horus_system/features/fleet/domain/entities/vehicle_status.dart';
import 'package:test/test.dart';

void main() {
  group('Fleet business-date mapping', () {
    test('tractor model preserves license expiry calendar date', () {
      final model = TractorHeadModel.fromMap({
        'id': 'tractor-1',
        'company_id': 'company-1',
        'plate_number': 'DXB-101',
        'license_expiry_date': '2026-09-07',
        'status': 'available',
        'is_active': true,
      });

      expect(
        model.licenseExpiryDate,
        BusinessDate(year: 2026, month: 9, day: 7),
      );
      expect(model.toEntity().licenseExpiryDate, model.licenseExpiryDate);
    });

    test('trailer model preserves license expiry calendar date', () {
      final model = TrailerModel.fromMap({
        'id': 'trailer-1',
        'company_id': 'company-1',
        'plate_number': 'TRL-101',
        'license_expiry_date': '2026-09-07',
        'status': 'available',
        'is_active': true,
      });

      expect(
        model.licenseExpiryDate,
        BusinessDate(year: 2026, month: 9, day: 7),
      );
      expect(model.toEntity().licenseExpiryDate, model.licenseExpiryDate);
    });

    test('tractor write data serializes exact date without timestamp', () {
      final data = TractorHeadWriteData(
        companyId: 'company-1',
        plateNumber: 'DXB-101',
        status: VehicleStatus.available,
        licenseExpiryDate: BusinessDate(year: 2026, month: 9, day: 7),
      );

      final map = data.toInsertMap();

      expect(map['license_expiry_date'], '2026-09-07');
    });

    test('trailer write data serializes exact date without timestamp', () {
      final data = TrailerWriteData(
        companyId: 'company-1',
        plateNumber: 'TRL-101',
        status: VehicleStatus.available,
        licenseExpiryDate: BusinessDate(year: 2026, month: 9, day: 7),
      );

      final map = data.toInsertMap();

      expect(map['license_expiry_date'], '2026-09-07');
    });

    test('fleet models reject timestamp-shaped license dates', () {
      expect(
        () => TractorHeadModel.fromMap({
          'id': 'tractor-1',
          'company_id': 'company-1',
          'plate_number': 'DXB-101',
          'license_expiry_date': '2026-09-07T00:00:00Z',
          'status': 'available',
          'is_active': true,
        }),
        throwsFormatException,
      );

      expect(
        () => TrailerModel.fromMap({
          'id': 'trailer-1',
          'company_id': 'company-1',
          'plate_number': 'TRL-101',
          'license_expiry_date': '2026-09-07T00:00:00Z',
          'status': 'available',
          'is_active': true,
        }),
        throwsFormatException,
      );
    });
  });
}
