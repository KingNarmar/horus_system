import 'package:intl/intl.dart';

String formatCustomerStatementDate(DateTime date, String localeName) {
  return DateFormat.yMMMd(localeName).format(date);
}
