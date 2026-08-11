import 'package:intl/intl.dart';

String formatPaymentDate(DateTime date, String localeName) {
  return DateFormat.yMMMd(localeName).format(date);
}

String formatPaymentDateTime(DateTime date, String localeName) {
  return DateFormat.yMMMd(localeName).add_jm().format(date.toLocal());
}
