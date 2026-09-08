import 'package:horus_system/core/data/services/timezone_business_time_zone_converter.dart';
import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:test/test.dart';

void main() {
  const converter = TimezoneBusinessTimeZoneConverter();

  group('TimezoneBusinessTimeZoneConverter', () {
    test('converts Dubai wall clock to the correct UTC instant', () {
      final result = converter.toUtcInstant(
        localDateTime: _local(2026, 9, 7, 0, 30),
        timeZoneId: 'Asia/Dubai',
      );

      expect(result, isA<Success<DateTime>>());
      final instant = (result as Success<DateTime>).data;
      expect(instant, DateTime.utc(2026, 9, 6, 20, 30));
      expect(instant.isUtc, isTrue);
    });

    test('renders a UTC instant using the requested company timezone', () {
      final result = converter.toBusinessLocalDateTime(
        instant: DateTime.utc(2026, 9, 6, 20, 30),
        timeZoneId: 'Asia/Dubai',
      );

      expect(result, isA<Success<BusinessLocalDateTime>>());
      expect(
        (result as Success<BusinessLocalDateTime>).data,
        _local(2026, 9, 7, 0, 30),
      );
    });

    test('rejects a nonexistent DST wall-clock time', () {
      final result = converter.toUtcInstant(
        localDateTime: _local(2026, 3, 8, 2, 30),
        timeZoneId: 'America/New_York',
      );

      expect(result, isA<FailureResult<DateTime>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationTripBusinessLocalDateTimeInvalid,
      );
    });

    test('rejects an ambiguous DST wall-clock time', () {
      final result = converter.toUtcInstant(
        localDateTime: _local(2026, 11, 1, 1, 30),
        timeZoneId: 'America/New_York',
      );

      expect(result, isA<FailureResult<DateTime>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationTripBusinessLocalDateTimeInvalid,
      );
    });

    test('rejects non-UTC instant input at the data boundary', () {
      final result = converter.toBusinessLocalDateTime(
        instant: DateTime(2026, 9, 6, 20, 30),
        timeZoneId: 'Asia/Dubai',
      );

      expect(result, isA<FailureResult<BusinessLocalDateTime>>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
    });
  });
}

BusinessLocalDateTime _local(
  int year,
  int month,
  int day,
  int hour,
  int minute,
) {
  return BusinessLocalDateTime(
    year: year,
    month: month,
    day: day,
    hour: hour,
    minute: minute,
  );
}
