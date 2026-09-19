import 'package:horus_system/core/constants/app_date_constraints.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/fleet/presentation/helpers/fleet_license_expiry_update_picker.dart';
import 'package:test/test.dart';

void main() {
  group('fleet license expiry trusted-date bounds', () {
    final businessDate = BusinessDate(year: 2026, month: 9, day: 19);

    test('derives the lower bound from the supplied business date', () {
      expect(
        fleetLicenseExpiryFirstDate(businessDate),
        DateTime(2026 - AppDateConstraints.fleetLicenseExpiryPastYears, 9, 19),
      );
    });

    test('derives the upper bound from the supplied business date', () {
      expect(
        fleetLicenseExpiryLastDate(businessDate),
        DateTime(
          2026 + AppDateConstraints.fleetLicenseExpiryFutureYears,
          9,
          19,
        ),
      );
    });
  });
}
