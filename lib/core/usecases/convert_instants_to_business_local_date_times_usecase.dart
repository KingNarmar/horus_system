import '../domain/services/business_time_zone_converter.dart';
import '../domain/value_objects/business_local_date_time.dart';
import '../utils/result.dart';
import 'usecase.dart';

final class ConvertInstantsToBusinessLocalDateTimesParams {
  final String timeZoneId;
  final Map<String, DateTime> instantsByKey;

  const ConvertInstantsToBusinessLocalDateTimesParams({
    required this.timeZoneId,
    required this.instantsByKey,
  });
}

final class ConvertInstantsToBusinessLocalDateTimesUseCase
    implements
        UseCase<
          Map<String, BusinessLocalDateTime>,
          ConvertInstantsToBusinessLocalDateTimesParams
        > {
  final BusinessTimeZoneConverter _converter;

  const ConvertInstantsToBusinessLocalDateTimesUseCase(this._converter);

  @override
  Future<Result<Map<String, BusinessLocalDateTime>>> call(
    ConvertInstantsToBusinessLocalDateTimesParams params,
  ) async {
    final values = <String, BusinessLocalDateTime>{};
    final timeZoneId = params.timeZoneId.trim();

    for (final entry in params.instantsByKey.entries) {
      final result = _converter.toBusinessLocalDateTime(
        instant: entry.value,
        timeZoneId: timeZoneId,
      );
      if (result is FailureResult<BusinessLocalDateTime>) {
        return FailureResult(result.failure);
      }
      values[entry.key] = (result as Success<BusinessLocalDateTime>).data;
    }

    return Success(Map.unmodifiable(values));
  }
}
