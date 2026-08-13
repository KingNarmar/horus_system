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
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? emptyValue : normalized;
}
