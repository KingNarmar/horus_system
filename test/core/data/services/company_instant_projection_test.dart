import 'package:horus_system/core/data/services/timezone_business_time_zone_converter.dart';
import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import 'package:test/test.dart';

void main() {
  const useCase = ConvertInstantsToBusinessLocalDateTimesUseCase(
    TimezoneBusinessTimeZoneConverter(),
  );

  test(
    'projects generic keyed instants across midnight without changing input',
    () async {
      final instant = DateTime.utc(2026, 12, 31, 20, 30);
      final instants = {'created': instant, 'audit': instant};
      final result = await useCase(
        ConvertInstantsToBusinessLocalDateTimesParams(
          timeZoneId: ' Asia/Dubai ',
          instantsByKey: instants,
        ),
      );

      final expected = BusinessLocalDateTime(
        year: 2027,
        month: 1,
        day: 1,
        hour: 0,
        minute: 30,
      );
      expect(result.dataOrNull, {'created': expected, 'audit': expected});
      expect(instants['created'], same(instant));
      expect(instant.isUtc, isTrue);
      expect(
        () => result.dataOrNull!['other'] = expected,
        throwsUnsupportedError,
      );
    },
  );

  test(
    'successive company timezones do not reuse previous projections',
    () async {
      final instants = {'event': DateTime.utc(2026, 9, 6, 20, 30)};
      for (final entry in {
        'Asia/Dubai': BusinessLocalDateTime(
          year: 2026,
          month: 9,
          day: 7,
          hour: 0,
          minute: 30,
        ),
        'America/New_York': BusinessLocalDateTime(
          year: 2026,
          month: 9,
          day: 6,
          hour: 16,
          minute: 30,
        ),
        'UTC': BusinessLocalDateTime(
          year: 2026,
          month: 9,
          day: 6,
          hour: 20,
          minute: 30,
        ),
      }.entries) {
        final result = await useCase(
          ConvertInstantsToBusinessLocalDateTimesParams(
            timeZoneId: entry.key,
            instantsByKey: instants,
          ),
        );
        expect(result.dataOrNull?['event'], entry.value);
      }
    },
  );

  test('invalid timezone returns a typed failure with no projection', () async {
    final result = await useCase(
      ConvertInstantsToBusinessLocalDateTimesParams(
        timeZoneId: 'Invalid/Company',
        instantsByKey: {'event': DateTime.utc(2026, 9, 7)},
      ),
    );
    expect(result.failureOrNull?.code, FailureCodes.serverError);
    expect(result.dataOrNull, isNull);
  });

  test(
    'non-UTC entry fails the batch without exposing partial values',
    () async {
      final result = await useCase(
        ConvertInstantsToBusinessLocalDateTimesParams(
          timeZoneId: 'Asia/Dubai',
          instantsByKey: {
            'valid': DateTime.utc(2026, 9, 7),
            'invalid': DateTime(2026, 9, 7),
          },
        ),
      );
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.dataOrNull, isNull);
    },
  );
}
