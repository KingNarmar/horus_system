import 'package:intl/intl.dart';

import '../domain/value_objects/money.dart';

String formatLocalizedMoney(
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
  if (exponent < 0 || exponent > 4) {
    throw ArgumentError.value(exponent, 'fractionDigits');
  }

  var result = 1;
  for (var index = 0; index < exponent; index++) {
    result *= 10;
  }
  return result;
}
