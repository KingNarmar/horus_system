import 'package:horus_system/core/domain/services/business_time_zone_converter.dart';
import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:horus_system/core/utils/result.dart';

final class FakeBusinessTimeZoneConverter implements BusinessTimeZoneConverter {
  final Duration offset;

  const FakeBusinessTimeZoneConverter({this.offset = Duration.zero});

  @override
  Result<BusinessLocalDateTime> toBusinessLocalDateTime({
    required DateTime instant,
    required String timeZoneId,
  }) {
    final local = instant.toUtc().add(offset);
    return Success(
      BusinessLocalDateTime(
        year: local.year,
        month: local.month,
        day: local.day,
        hour: local.hour,
        minute: local.minute,
      ),
    );
  }

  @override
  Result<DateTime> toUtcInstant({
    required BusinessLocalDateTime localDateTime,
    required String timeZoneId,
  }) {
    final carrier = DateTime.utc(
      localDateTime.year,
      localDateTime.month,
      localDateTime.day,
      localDateTime.hour,
      localDateTime.minute,
    );
    return Success(carrier.subtract(offset).toUtc());
  }
}
