import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/reports/data/services/report_pdf_date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
  });

  test('Arabic business date excludes PDF-unsafe bidi controls', () {
    final result = ReportPdfDateFormatter.businessDate(
      BusinessDate(year: 2026, month: 11, day: 19),
      'ar',
    );

    expect(result, isNotEmpty);
    expect(
      RegExp(
        r'[\u061C\u200E\u200F\u202A-\u202E\u2066-\u2069]',
      ).hasMatch(result),
      isFalse,
    );
  });

  test('UTC generation timestamp is readable without ISO microseconds', () {
    final result = ReportPdfDateFormatter.generatedAtUtc(
      DateTime.utc(2026, 11, 19, 12, 10, 15, 630),
      'ar',
    );

    expect(result, endsWith(' UTC'));
    expect(result, isNot(contains('2026-11-19T')));
    expect(result, isNot(contains('.630')));
    expect(
      RegExp(
        r'[\u061C\u200E\u200F\u202A-\u202E\u2066-\u2069]',
      ).hasMatch(result),
      isFalse,
    );
  });

  test('English business date remains localized', () {
    final result = ReportPdfDateFormatter.businessDate(
      BusinessDate(year: 2026, month: 11, day: 19),
      'en',
    );

    expect(result, contains('2026'));
    expect(result, contains('11'));
  });
}
