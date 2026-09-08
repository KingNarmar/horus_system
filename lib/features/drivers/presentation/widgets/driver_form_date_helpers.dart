import '../../../../core/constants/app_date_constraints.dart';
import '../../../../core/domain/value_objects/business_date.dart';

DateTime driverLicenseExpiryFirstDate(DateTime today) {
  return DateTime(
    today.year - AppDateConstraints.driverLicenseExpiryPastYears,
    today.month,
    today.day,
  );
}

DateTime driverLicenseExpiryLastDate(DateTime today) {
  return DateTime(
    today.year + AppDateConstraints.driverLicenseExpiryFutureYears,
    today.month,
    today.day,
  );
}

String driverFormDateOnly(BusinessDate value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
