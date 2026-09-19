import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/drivers/domain/policies/driver_license_expiry_policy.dart';
import 'package:test/test.dart';

void main() {
  group('DriverLicenseExpiryPolicy', () {
    final businessDate = BusinessDate(year: 2026, month: 9, day: 19);

    test('allows missing, same-day, and future expiry dates', () {
      expect(
        DriverLicenseExpiryPolicy.isValid(
          licenseExpiryDate: null,
          currentBusinessDate: businessDate,
        ),
        isTrue,
      );
      expect(
        DriverLicenseExpiryPolicy.isValid(
          licenseExpiryDate: BusinessDate(year: 2026, month: 9, day: 19),
          currentBusinessDate: businessDate,
        ),
        isTrue,
      );
      expect(
        DriverLicenseExpiryPolicy.isValid(
          licenseExpiryDate: BusinessDate(year: 2026, month: 9, day: 20),
          currentBusinessDate: businessDate,
        ),
        isTrue,
      );
    });

    test('rejects an expiry date before the company business date', () {
      expect(
        DriverLicenseExpiryPolicy.isValid(
          licenseExpiryDate: BusinessDate(year: 2026, month: 9, day: 18),
          currentBusinessDate: businessDate,
        ),
        isFalse,
      );
    });
  });
}
