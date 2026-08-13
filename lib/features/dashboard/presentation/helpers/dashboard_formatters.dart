import 'package:intl/intl.dart';

import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/localization/money_formatter.dart';

String formatDashboardDate(DateTime date, String localeName) {
  return DateFormat.yMMMd(localeName).format(date);
}

String formatDashboardMoney({
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
