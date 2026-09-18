import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../repositories/trips_repository.dart';

Failure? validateTripWriteData({
  required String customerId,
  required String routeId,
  required DateTime? scheduledLoadingAt,
  required DateTime? scheduledDeliveryAt,
  required DateTime? actualLoadingAt,
  required DateTime? actualDeliveryAt,
}) {
  if (customerId.trim().isEmpty) {
    return const ValidationFailure(
      code: FailureCodes.validationTripCustomerRequired,
      message: 'Customer is required.',
    );
  }

  if (routeId.trim().isEmpty) {
    return const ValidationFailure(
      code: FailureCodes.validationTripRouteRequired,
      message: 'Route is required.',
    );
  }

  final scheduledPairFailure = _validateTemporalPair(
    loadingAt: scheduledLoadingAt,
    deliveryAt: scheduledDeliveryAt,
  );
  if (scheduledPairFailure != null) return scheduledPairFailure;

  return _validateTemporalPair(
    loadingAt: actualLoadingAt,
    deliveryAt: actualDeliveryAt,
  );
}

Failure? _validateTemporalPair({
  required DateTime? loadingAt,
  required DateTime? deliveryAt,
}) {
  if (loadingAt == null || deliveryAt == null) return null;

  if (deliveryAt.isBefore(loadingAt)) {
    return const ValidationFailure(
      code: FailureCodes.validationTripDeliveryBeforeLoading,
      message: 'Delivery cannot be before loading.',
    );
  }

  return null;
}

Future<Failure?> validateVehicleAvailability({
  required TripsRepository repository,
  required String companyId,
  required String? tractorHeadId,
  required String? trailerId,
  String? excludingTripId,
}) async {
  if (tractorHeadId == null && trailerId == null) {
    return null;
  }

  final result = await repository.hasOpenTripForVehicle(
    companyId: companyId,
    tractorHeadId: tractorHeadId,
    trailerId: trailerId,
    excludingTripId: excludingTripId,
  );

  if (result is FailureResult<bool>) {
    return result.failure;
  }

  final hasOpenTrip = (result as Success<bool>).data;

  if (hasOpenTrip) {
    return const ConflictFailure(
      code: FailureCodes.conflictTripVehicleAlreadyOpen,
      message: 'This vehicle already has an open trip.',
    );
  }

  return null;
}

String? optionalTripText(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
