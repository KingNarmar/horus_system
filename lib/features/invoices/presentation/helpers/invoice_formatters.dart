import 'package:intl/intl.dart';

import '../../../../core/domain/value_objects/money.dart';

String formatInvoiceDate(DateTime? date, String localeName, String fallback) {
  if (date == null) return fallback;
  return DateFormat.yMMMd(localeName).format(date);
}

String formatInvoiceDateTime(
  DateTime date,
  String localeName,
) {
  return DateFormat.yMMMd(localeName).add_jm().format(date.toLocal());
}

String formatInvoiceInputDate(DateTime? date) {
  if (date == null) return '';
  return DateFormat('yyyy-MM-dd').format(date);
}

String formatInvoiceMoney(
  Money money, {
  required int fractionDigits,
  required String localeName,
}) {
  final divisor = _powerOfTen(fractionDigits);
  final amount = money.minorUnits / divisor;
  final pattern = fractionDigits == 0
      ? '#,##0'
      : '#,##0.${List.filled(fractionDigits, '0').join()}';
  final formatted = NumberFormat(pattern, localeName).format(amount);
  return '${money.currency.value} $formatted';
}

int _powerOfTen(int exponent) {
  var result = 1;
  for (var index = 0; index < exponent; index++) {
    result *= 10;
  }
  return result;
}
