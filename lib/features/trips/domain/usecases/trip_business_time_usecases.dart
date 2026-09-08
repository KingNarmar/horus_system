import '../../../../core/domain/services/business_time_zone_converter.dart';
import '../../../../core/domain/value_objects/business_local_date_time.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../entities/trip_business_local_timestamps.dart';
import '../entities/trip_entity.dart';
import '../entities/trip_timestamp_instants.dart';

final class ResolveTripBusinessLocalTimestampsParams {
  final CurrentCompanyContext currentCompanyContext;
  final BusinessLocalDateTime? scheduledLoadingAt;
  final BusinessLocalDateTime? scheduledDeliveryAt;
  final BusinessLocalDateTime? actualLoadingAt;
  final BusinessLocalDateTime? actualDeliveryAt;

  const ResolveTripBusinessLocalTimestampsParams({
    required this.currentCompanyContext,
    this.scheduledLoadingAt,
    this.scheduledDeliveryAt,
    this.actualLoadingAt,
    this.actualDeliveryAt,
  });
}

final class GetTripBusinessLocalTimestampsParams {
  final CurrentCompanyContext currentCompanyContext;
  final TripEntity trip;

  const GetTripBusinessLocalTimestampsParams({
    required this.currentCompanyContext,
    required this.trip,
  });
}

final class ResolveTripBusinessLocalTimestampsUseCase
    implements
        UseCase<
          TripTimestampInstants,
          ResolveTripBusinessLocalTimestampsParams
        > {
  final BusinessTimeZoneConverter _converter;

  const ResolveTripBusinessLocalTimestampsUseCase(this._converter);

  @override
  Future<Result<TripTimestampInstants>> call(
    ResolveTripBusinessLocalTimestampsParams params,
  ) async {
    final timeZoneId = _businessTimeZone(params.currentCompanyContext);
    if (timeZoneId == null) {
      return const FailureResult<TripTimestampInstants>(
        ConflictFailure(
          code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        ),
      );
    }

    final scheduledLoading = _toUtc(params.scheduledLoadingAt, timeZoneId);
    if (scheduledLoading is FailureResult<DateTime?>) {
      return FailureResult(scheduledLoading.failure);
    }

    final scheduledDelivery = _toUtc(params.scheduledDeliveryAt, timeZoneId);
    if (scheduledDelivery is FailureResult<DateTime?>) {
      return FailureResult(scheduledDelivery.failure);
    }

    final actualLoading = _toUtc(params.actualLoadingAt, timeZoneId);
    if (actualLoading is FailureResult<DateTime?>) {
      return FailureResult(actualLoading.failure);
    }

    final actualDelivery = _toUtc(params.actualDeliveryAt, timeZoneId);
    if (actualDelivery is FailureResult<DateTime?>) {
      return FailureResult(actualDelivery.failure);
    }

    return Success(
      TripTimestampInstants(
        scheduledLoadingAt: scheduledLoading.dataOrNull,
        scheduledDeliveryAt: scheduledDelivery.dataOrNull,
        actualLoadingAt: actualLoading.dataOrNull,
        actualDeliveryAt: actualDelivery.dataOrNull,
      ),
    );
  }

  Result<DateTime?> _toUtc(BusinessLocalDateTime? value, String timeZoneId) {
    if (value == null) return const Success<DateTime?>(null);
    final result = _converter.toUtcInstant(
      localDateTime: value,
      timeZoneId: timeZoneId,
    );
    return result.when(
      success: (instant) => Success<DateTime?>(instant),
      failure: (failure) => FailureResult<DateTime?>(failure),
    );
  }
}

final class GetTripBusinessLocalTimestampsUseCase
    implements
        UseCase<
          TripBusinessLocalTimestamps,
          GetTripBusinessLocalTimestampsParams
        > {
  final BusinessTimeZoneConverter _converter;

  const GetTripBusinessLocalTimestampsUseCase(this._converter);

  @override
  Future<Result<TripBusinessLocalTimestamps>> call(
    GetTripBusinessLocalTimestampsParams params,
  ) async {
    final timeZoneId = _businessTimeZone(params.currentCompanyContext);
    if (timeZoneId == null) {
      return const FailureResult<TripBusinessLocalTimestamps>(
        ConflictFailure(
          code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        ),
      );
    }

    final scheduledLoading = _toLocal(
      params.trip.scheduledLoadingAt,
      timeZoneId,
    );
    if (scheduledLoading is FailureResult<BusinessLocalDateTime?>) {
      return FailureResult(scheduledLoading.failure);
    }

    final scheduledDelivery = _toLocal(
      params.trip.scheduledDeliveryAt,
      timeZoneId,
    );
    if (scheduledDelivery is FailureResult<BusinessLocalDateTime?>) {
      return FailureResult(scheduledDelivery.failure);
    }

    final actualLoading = _toLocal(params.trip.actualLoadingAt, timeZoneId);
    if (actualLoading is FailureResult<BusinessLocalDateTime?>) {
      return FailureResult(actualLoading.failure);
    }

    final actualDelivery = _toLocal(params.trip.actualDeliveryAt, timeZoneId);
    if (actualDelivery is FailureResult<BusinessLocalDateTime?>) {
      return FailureResult(actualDelivery.failure);
    }

    return Success(
      TripBusinessLocalTimestamps(
        scheduledLoadingAt: scheduledLoading.dataOrNull,
        scheduledDeliveryAt: scheduledDelivery.dataOrNull,
        actualLoadingAt: actualLoading.dataOrNull,
        actualDeliveryAt: actualDelivery.dataOrNull,
      ),
    );
  }

  Result<BusinessLocalDateTime?> _toLocal(DateTime? value, String timeZoneId) {
    if (value == null) return const Success<BusinessLocalDateTime?>(null);
    final result = _converter.toBusinessLocalDateTime(
      instant: value,
      timeZoneId: timeZoneId,
    );
    return result.when(
      success: (localDateTime) =>
          Success<BusinessLocalDateTime?>(localDateTime),
      failure: (failure) => FailureResult<BusinessLocalDateTime?>(failure),
    );
  }
}

String? _businessTimeZone(CurrentCompanyContext context) {
  final timeZoneId = context.company.businessTimezone?.trim();
  if (timeZoneId == null || timeZoneId.isEmpty) return null;
  return timeZoneId;
}
