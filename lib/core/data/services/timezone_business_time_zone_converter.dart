import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/services/business_time_zone_converter.dart';
import '../../domain/value_objects/business_local_date_time.dart';
import '../../errors/common_failures.dart';
import '../../errors/failure_codes.dart';
import '../../utils/result.dart';

final class TimezoneBusinessTimeZoneConverter
    implements BusinessTimeZoneConverter {
  const TimezoneBusinessTimeZoneConverter();

  static bool _isTimeZoneDatabaseInitialized = false;

  @override
  Result<DateTime> toUtcInstant({
    required BusinessLocalDateTime localDateTime,
    required String timeZoneId,
  }) {
    final location = _locationOrNull(timeZoneId);
    if (location == null) {
      return const FailureResult<DateTime>(
        ServerFailure(code: FailureCodes.serverError),
      );
    }

    try {
      final candidate = tz.TZDateTime(
        location,
        localDateTime.year,
        localDateTime.month,
        localDateTime.day,
        localDateTime.hour,
        localDateTime.minute,
      );

      if (!_sameWallClock(candidate, localDateTime) ||
          _hasAlternativeInstant(candidate, location, localDateTime)) {
        return const FailureResult<DateTime>(
          ValidationFailure(
            code: FailureCodes.validationTripBusinessLocalDateTimeInvalid,
          ),
        );
      }

      return Success(candidate.toUtc());
    } catch (_) {
      return const FailureResult<DateTime>(UnexpectedFailure());
    }
  }

  @override
  Result<BusinessLocalDateTime> toBusinessLocalDateTime({
    required DateTime instant,
    required String timeZoneId,
  }) {
    if (!instant.isUtc) {
      return const FailureResult<BusinessLocalDateTime>(
        ServerFailure(code: FailureCodes.serverError),
      );
    }

    final location = _locationOrNull(timeZoneId);
    if (location == null) {
      return const FailureResult<BusinessLocalDateTime>(
        ServerFailure(code: FailureCodes.serverError),
      );
    }

    try {
      final local = tz.TZDateTime.from(instant, location);
      final value = BusinessLocalDateTime.tryCreate(
        year: local.year,
        month: local.month,
        day: local.day,
        hour: local.hour,
        minute: local.minute,
      );
      if (value == null) {
        return const FailureResult<BusinessLocalDateTime>(
          ServerFailure(code: FailureCodes.serverError),
        );
      }
      return Success(value);
    } catch (_) {
      return const FailureResult<BusinessLocalDateTime>(UnexpectedFailure());
    }
  }

  tz.Location? _locationOrNull(String timeZoneId) {
    _ensureTimeZoneDatabaseInitialized();
    final normalized = timeZoneId.trim();
    if (normalized.isEmpty) return null;

    try {
      return tz.getLocation(normalized);
    } on tz.LocationNotFoundException {
      return null;
    }
  }

  void _ensureTimeZoneDatabaseInitialized() {
    if (_isTimeZoneDatabaseInitialized) return;
    tz_data.initializeTimeZones();
    _isTimeZoneDatabaseInitialized = true;
  }

  bool _hasAlternativeInstant(
    tz.TZDateTime candidate,
    tz.Location location,
    BusinessLocalDateTime localDateTime,
  ) {
    final instant = candidate.toUtc();
    for (var minutes = -180; minutes <= 180; minutes++) {
      if (minutes == 0) continue;
      final alternative = tz.TZDateTime.from(
        instant.add(Duration(minutes: minutes)),
        location,
      );
      if (_sameWallClock(alternative, localDateTime)) return true;
    }
    return false;
  }

  bool _sameWallClock(DateTime value, BusinessLocalDateTime localDateTime) {
    return value.year == localDateTime.year &&
        value.month == localDateTime.month &&
        value.day == localDateTime.day &&
        value.hour == localDateTime.hour &&
        value.minute == localDateTime.minute;
  }
}
