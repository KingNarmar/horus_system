import 'package:flutter/material.dart';

import '../../../../core/domain/value_objects/business_local_date_time.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/utils/business_local_date_time_date_time_adapter.dart';

class CustomerDateTimeFormatter {
  static String format(BuildContext context, BusinessLocalDateTime? value) {
    if (value == null) return context.l10n.customerEmptyValue;
    final localValue = BusinessLocalDateTimeDateTimeAdapter.toDateTime(value);
    final materialLocalizations = MaterialLocalizations.of(context);
    final date = materialLocalizations.formatMediumDate(localValue);
    final time = TimeOfDay.fromDateTime(localValue).format(context);
    return '$date, $time';
  }
}
