import '../../utils/result.dart';
import '../value_objects/business_local_date_time.dart';

abstract interface class BusinessTimeZoneConverter {
  Result<DateTime> toUtcInstant({
    required BusinessLocalDateTime localDateTime,
    required String timeZoneId,
  });

  Result<BusinessLocalDateTime> toBusinessLocalDateTime({
    required DateTime instant,
    required String timeZoneId,
  });
}
