import '../../../../core/domain/value_objects/business_date.dart';

abstract final class FleetLicenseExpiryPolicy {
  static bool isValid({
    required BusinessDate? licenseExpiryDate,
    required BusinessDate currentBusinessDate,
  }) {
    return licenseExpiryDate == null ||
        !licenseExpiryDate.isBefore(currentBusinessDate);
  }
}
