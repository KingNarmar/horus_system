import 'package:horus_system/features/drivers/data/mappers/driver_mapper.dart';
import 'package:horus_system/features/drivers/data/models/driver_model.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('DriverMapper image paths', () {
    test('maps driver image paths from model to entity', () {
      final model = DriverModel.fromMap(const {
        'id': 'driver-1',
        'company_id': 'company-1',
        'full_name': 'Driver',
        'profile_image_path':
            'companies/company-1/drivers/driver-1/profile/a.jpg',
        'license_image_path':
            'companies/company-1/drivers/driver-1/license-front/a.jpg',
        'license_back_image_path':
            'companies/company-1/drivers/driver-1/license-back/a.jpg',
        'national_id_image_path':
            'companies/company-1/drivers/driver-1/national-id-front/a.jpg',
        'national_id_back_image_path':
            'companies/company-1/drivers/driver-1/national-id-back/a.jpg',
      });

      final entity = model.toEntity();

      expect(entity.profileImagePath, model.profileImagePath);
      expect(entity.licenseImagePath, model.licenseImagePath);
      expect(entity.licenseBackImagePath, model.licenseBackImagePath);
      expect(entity.nationalIdImagePath, model.nationalIdImagePath);
      expect(entity.nationalIdBackImagePath, model.nationalIdBackImagePath);
    });

    test('writes driver image paths to insert and update maps', () {
      final data = DriverWriteData(
        companyId: 'company-1',
        fullName: 'Driver',
        licenseExpiryDate: DateTime(2026, 8, 18),
        profileImagePath: 'profile-path',
        licenseImagePath: 'license-front-path',
        licenseBackImagePath: 'license-back-path',
        nationalIdImagePath: 'national-id-front-path',
        nationalIdBackImagePath: 'national-id-back-path',
      );

      expect(
        data.toInsertMap(),
        containsPair('license_expiry_date', '2026-08-18'),
      );
      expect(
        data.toInsertMap(),
        containsPair('profile_image_path', 'profile-path'),
      );
      expect(
        data.toInsertMap(),
        containsPair('license_image_path', 'license-front-path'),
      );
      expect(
        data.toInsertMap(),
        containsPair('license_back_image_path', 'license-back-path'),
      );
      expect(
        data.toInsertMap(),
        containsPair('national_id_image_path', 'national-id-front-path'),
      );
      expect(
        data.toInsertMap(),
        containsPair('national_id_back_image_path', 'national-id-back-path'),
      );
      expect(
        data.toUpdateMap(),
        containsPair('license_expiry_date', '2026-08-18'),
      );
      expect(
        data.toUpdateMap(),
        containsPair('profile_image_path', 'profile-path'),
      );
      expect(
        data.toUpdateMap(),
        containsPair('license_image_path', 'license-front-path'),
      );
      expect(
        data.toUpdateMap(),
        containsPair('license_back_image_path', 'license-back-path'),
      );
      expect(
        data.toUpdateMap(),
        containsPair('national_id_image_path', 'national-id-front-path'),
      );
      expect(
        data.toUpdateMap(),
        containsPair('national_id_back_image_path', 'national-id-back-path'),
      );
    });
  });
}
