import 'package:intl/intl.dart';

import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/utils/business_date_date_time_adapter.dart';
import '../../../../core/localization/money_formatter.dart';

String formatReportDate(BusinessDate date, String localeName) {
  return DateFormat.yMMMd(
    localeName,
  ).format(BusinessDateDateTimeAdapter.toDateTime(date));
}

String formatReportMoney({
  required Money money,
  required int fractionDigits,
  required String localeName,
}) {
  return formatLocalizedMoney(
    money,
    fractionDigits: fractionDigits,
    localeName: localeName,
  );
}

String reportDisplayValue(String? value, String emptyValue) {
  return _normalizedText(value) ?? emptyValue;
}

String reportTripDisplayValue({
  required String? tripNumber,
  required String? loadingOrderNumber,
  required String? waybillNumber,
  required String loadingLocation,
  required String unloadingLocation,
  required String emptyValue,
}) {
  for (final reference in [tripNumber, loadingOrderNumber, waybillNumber]) {
    final normalized = _normalizedText(reference);
    if (normalized != null) return normalized;
  }

  return reportRouteDisplayValue(
    loadingLocation: loadingLocation,
    unloadingLocation: unloadingLocation,
    emptyValue: emptyValue,
  );
}

String reportRouteDisplayValue({
  required String loadingLocation,
  required String unloadingLocation,
  required String emptyValue,
}) {
  final loading = _normalizedText(loadingLocation);
  final unloading = _normalizedText(unloadingLocation);
  if (loading != null && unloading != null) return '$loading → $unloading';
  if (loading != null) return loading;
  if (unloading != null) return unloading;
  return emptyValue;
}

String? _normalizedText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
