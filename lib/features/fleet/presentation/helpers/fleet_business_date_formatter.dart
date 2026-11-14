import 'package:flutter/material.dart';

import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/utils/business_date_date_time_adapter.dart';

/// Formats calendar-only business dates for Fleet presentation.
abstract final class FleetBusinessDateFormatter {
  static String format(BuildContext context, BusinessDate value) {
    return MaterialLocalizations.of(
      context,
    ).formatShortDate(BusinessDateDateTimeAdapter.toDateTime(value));
  }

  static String formatOrFallback(
    BuildContext context,
    BusinessDate? value, {
    required String fallback,
  }) {
    if (value == null) return fallback;
    return formatInline(context, value);
  }

  /// Keeps the date's numeric order intact inside surrounding RTL copy.
  static String formatInline(BuildContext context, BusinessDate value) {
    return '\u2066${format(context, value)}\u2069';
  }
}
