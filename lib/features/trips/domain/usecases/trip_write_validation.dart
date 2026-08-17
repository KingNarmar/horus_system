import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../repositories/trips_repository.dart';

Failure? validateTripWriteData({
  required String customerId,
  required String routeId,
  required double? quantityTons,
  required double? freightPrice,
  required DateTime? scheduledLoadingAt,
  required DateTime? scheduledDeliveryAt,
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

  if (quantityTons != null && quantityTons < 0) {
    return const ValidationFailure(
      code: FailureCodes.validationTripQuantityNegative,
      message: 'Quantity cannot be negative.',
    );
  }

  if (freightPrice != null && freightPrice < 0) {
    return const ValidationFailure(
      code: FailureCodes.validationTripFreightPriceNegative,
      message: 'Freight price cannot be negative.',
    );
  }

  if (scheduledLoadingAt != null &&
      scheduledDeliveryAt != null &&
      scheduledDeliveryAt.isBefore(scheduledLoadingAt)) {
    return const ValidationFailure(
      code: FailureCodes.validationTripDeliveryBeforeLoading,
      message: 'Scheduled delivery cannot be before scheduled loading.',
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
