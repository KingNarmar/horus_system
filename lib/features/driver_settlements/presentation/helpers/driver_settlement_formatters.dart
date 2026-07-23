import 'package:intl/intl.dart';

String formatDriverSettlementDate(DateTime date, String localeName) {
  return DateFormat.yMMMd(localeName).format(date);
}

String formatDriverSettlementDateTime(DateTime date, String localeName) {
  return DateFormat.yMMMd(localeName).add_jm().format(date.toLocal());
}

String formatDriverSettlementAmount(double amount, String localeName) {
  return NumberFormat('#,##0.00', localeName).format(amount);
}
