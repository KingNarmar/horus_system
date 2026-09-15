import 'package:intl/intl.dart';

import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/localization/money_formatter.dart';

String formatReportDate(DateTime date, String localeName) {
  return DateFormat.yMMMd(localeName).format(date);
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
