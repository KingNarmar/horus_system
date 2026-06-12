import 'package:flutter/material.dart';

class CustomerDateTimeFormatter {
  static String format(BuildContext context, DateTime value) {
    final localValue = value.toLocal();
    final materialLocalizations = MaterialLocalizations.of(context);
    final date = materialLocalizations.formatMediumDate(localValue);
    final time = TimeOfDay.fromDateTime(localValue).format(context);
    return '$date, $time';
  }
}
