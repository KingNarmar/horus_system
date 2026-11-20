import 'package:intl/intl.dart';

import '../../../../core/domain/value_objects/business_date.dart';

/// Presentation-only date strings for embedded PDF fonts.
///
/// Some locale patterns include invisible bidirectional controls; these
/// controls can render as missing-glyph boxes in PDF viewers.
abstract final class ReportPdfDateFormatter {
  static final RegExp _bidiControls = RegExp(
    r'[\u061C\u200E\u200F\u202A-\u202E\u2066-\u2069]',
  );

  static String businessDate(BusinessDate date, String localeName) =>
      _withoutControls(
        DateFormat.yMd(
          localeName,
        ).format(DateTime(date.year, date.month, date.day)),
      );

  static String utcTimestamp(DateTime utc, String localeName) {
    final display = DateFormat(
      'yyyy-MM-dd HH:mm',
      localeName,
    ).format(utc.toUtc());
    return '${_withoutControls(display)} UTC';
  }

  static String _withoutControls(String value) =>
      value.replaceAll(_bidiControls, '');
}
