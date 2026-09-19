import 'package:intl/intl.dart';

import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/utils/business_date_date_time_adapter.dart';
import '../../../../core/localization/money_formatter.dart';

String formatDashboardDate(BusinessDate date, String localeName) {
  return DateFormat.yMMMd(
    localeName,
  ).format(BusinessDateDateTimeAdapter.toDateTime(date));
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
