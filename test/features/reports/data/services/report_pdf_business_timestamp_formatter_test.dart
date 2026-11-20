import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:horus_system/core/data/services/timezone_business_time_zone_converter.dart';
import 'package:horus_system/features/reports/data/services/report_pdf_business_timestamp_formatter.dart';

void main() {
  const formatter = ReportPdfBusinessTimestampFormatter(
    TimezoneBusinessTimeZoneConverter(),
  );

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  test('uses company Dubai timezone instead of the UTC/device clock', () {
    final result = formatter.format(
      utcInstant: DateTime.utc(2026, 11, 20, 11, 20),
      businessTimezone: 'Asia/Dubai',
      localeName: 'en',
    );

    expect(result.failureOrNull, isNull);
    expect(result.dataOrNull, '2026-11-20 15:20 Asia/Dubai');
  });

  test('handles New York spring DST transition using IANA rules', () {
    final before = formatter.format(
      utcInstant: DateTime.utc(2026, 3, 8, 6, 30),
      businessTimezone: 'America/New_York',
      localeName: 'en',
    );
    final after = formatter.format(
      utcInstant: DateTime.utc(2026, 3, 8, 7, 30),
      businessTimezone: 'America/New_York',
      localeName: 'en',
    );

    expect(before.dataOrNull, '2026-03-08 01:30 America/New_York');
    expect(after.dataOrNull, '2026-03-08 03:30 America/New_York');
  });

  test('respects half-hour offsets rather than adding a fixed amount', () {
    final result = formatter.format(
      utcInstant: DateTime.utc(2026, 11, 20, 11, 20),
      businessTimezone: 'Asia/Kolkata',
      localeName: 'en',
    );

    expect(result.dataOrNull, '2026-11-20 16:50 Asia/Kolkata');
  });

  test('returns typed failure for an unknown company timezone', () {
    final result = formatter.format(
      utcInstant: DateTime.utc(2026, 11, 20, 11, 20),
      businessTimezone: 'Invalid/Timezone',
      localeName: 'en',
    );

    expect(result.isFailure, isTrue);
    expect(result.dataOrNull, isNull);
  });

  test('Arabic formatting remains in the company timezone', () {
    final result = formatter.format(
      utcInstant: DateTime.utc(2026, 11, 20, 11, 20),
      businessTimezone: 'Asia/Dubai',
      localeName: 'ar',
    );

    expect(result.failureOrNull, isNull);
    expect(result.dataOrNull, endsWith(' Asia/Dubai'));
    expect(result.dataOrNull, isNot(contains(' UTC')));
  });
}
