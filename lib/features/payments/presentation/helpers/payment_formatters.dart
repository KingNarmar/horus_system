import 'package:intl/intl.dart';

import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/business_local_date_time.dart';
import '../../../../core/utils/business_date_date_time_adapter.dart';
import '../../../../core/utils/business_local_date_time_date_time_adapter.dart';

String formatPaymentDate(BusinessDate date, String localeName) {
  return DateFormat.yMMMd(
    localeName,
  ).format(BusinessDateDateTimeAdapter.toDateTime(date));
}

String formatPaymentDateTime(
  BusinessLocalDateTime date,
  String localeName,
) {
  return DateFormat.yMMMd(localeName).add_jm().format(
    BusinessLocalDateTimeDateTimeAdapter.toDateTime(date),
  );
}
