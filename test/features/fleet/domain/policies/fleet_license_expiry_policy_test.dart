import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/fleet/domain/policies/fleet_license_expiry_policy.dart';
import 'package:test/test.dart';

void main() {
  group('FleetLicenseExpiryPolicy', () {
    final currentBusinessDate = BusinessDate(year: 2026, month: 9, day: 19);

    test('allows null, today, and future dates', () {
      expect(
        FleetLicenseExpiryPolicy.isValid(
          licenseExpiryDate: null,
          currentBusinessDate: currentBusinessDate,
        ),
        isTrue,
      );
      expect(
        FleetLicenseExpiryPolicy.isValid(
          licenseExpiryDate: BusinessDate(year: 2026, month: 9, day: 19),
          currentBusinessDate: currentBusinessDate,
        ),
        isTrue,
      );
      expect(
        FleetLicenseExpiryPolicy.isValid(
          licenseExpiryDate: BusinessDate(year: 2026, month: 9, day: 20),
          currentBusinessDate: currentBusinessDate,
        ),
        isTrue,
      );
    });

    test('rejects dates before the trusted business date', () {
      expect(
        FleetLicenseExpiryPolicy.isValid(
          licenseExpiryDate: BusinessDate(year: 2026, month: 9, day: 18),
          currentBusinessDate: currentBusinessDate,
        ),
        isFalse,
      );
    });
  });
}
