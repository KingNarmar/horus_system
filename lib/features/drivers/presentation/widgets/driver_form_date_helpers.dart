import '../../../../core/constants/app_date_constraints.dart';

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

String driverFormDateOnly(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

DateTime driverFormDateOnlyValue(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}
