import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../entities/trip_entity.dart';
import '../entities/trip_write_data.dart';
import '../policies/trips_permission_policy.dart';
import '../repositories/trips_repository.dart';
import 'trip_usecase_params.dart';
import 'trip_write_validation.dart';

class CreateTripUseCase implements UseCase<TripEntity, CreateTripParams> {
  final TripsRepository _repository;

  const CreateTripUseCase(this._repository);

  @override
  Future<Result<TripEntity>> call(CreateTripParams params) {
    return _createTrip(repository: _repository, params: params);
  }
}

class SaveTripUseCase implements UseCase<TripEntity, SaveTripParams> {
  final TripsRepository _repository;

  const SaveTripUseCase(this._repository);

  @override
  Future<Result<TripEntity>> call(SaveTripParams params) {
    return _saveTrip(repository: _repository, params: params);
  }
}

Future<Result<TripEntity>> _createTrip({
  required TripsRepository repository,
  required CreateTripParams params,
}) async {
  final context = params.currentCompanyContext;

  if (!TripsPermissionPolicy.canManageTrips(context.role)) {
    return const FailureResult<TripEntity>(
      PermissionFailure(
        code: FailureCodes.permissionTripsManagement,
        message: 'Trips management is not allowed.',
      ),
    );
  }

  final validationFailure = validateTripWriteData(
    customerId: params.customerId,
    routeId: params.routeId,
    quantityTons: params.quantityTons,
    freightPrice: params.freightPrice,
    scheduledLoadingAt: params.scheduledLoadingAt,
    scheduledDeliveryAt: params.scheduledDeliveryAt,
  );

  if (validationFailure != null) {
    return FailureResult<TripEntity>(validationFailure);
  }

  final duplicateVehicleFailure = await validateVehicleAvailability(
    repository: repository,
    companyId: context.companyId,
    tractorHeadId: optionalTripText(params.tractorHeadId),
    trailerId: optionalTripText(params.trailerId),
  );

  if (duplicateVehicleFailure != null) {
    return FailureResult<TripEntity>(duplicateVehicleFailure);
  }

  final data = TripWriteData(
    companyId: context.companyId,
    customerId: params.customerId.trim(),
    routeId: params.routeId.trim(),
    driverId: optionalTripText(params.driverId),
    tractorHeadId: optionalTripText(params.tractorHeadId),
    trailerId: optionalTripText(params.trailerId),
    loadingOrderNumber: optionalTripText(params.loadingOrderNumber),
    waybillNumber: optionalTripText(params.waybillNumber),
    quantityTons: params.quantityTons,
    freightPrice: params.freightPrice,
    scheduledLoadingAt: params.scheduledLoadingAt,
    scheduledDeliveryAt: params.scheduledDeliveryAt,
    actualLoadingAt: params.actualLoadingAt,
    actualDeliveryAt: params.actualDeliveryAt,
    notes: optionalTripText(params.notes),
  );

  return repository.createTrip(data: data, actorRole: context.role.value);
}

Future<Result<TripEntity>> _saveTrip({
  required TripsRepository repository,
  required SaveTripParams params,
}) async {
  final context = params.currentCompanyContext;

  if (!TripsPermissionPolicy.canManageTrips(context.role)) {
    return const FailureResult<TripEntity>(
      PermissionFailure(
        code: FailureCodes.permissionTripsManagement,
        message: 'Trips management is not allowed.',
      ),
    );
  }

  final id = optionalTripText(params.id);
  if (id == null) {
    return const FailureResult<TripEntity>(
      ValidationFailure(
        code: FailureCodes.validationTripIdRequired,
        message: 'Trip id is required.',
      ),
    );
  }

  final validationFailure = validateTripWriteData(
    customerId: params.customerId,
    routeId: params.routeId,
    quantityTons: params.quantityTons,
    freightPrice: params.freightPrice,
    scheduledLoadingAt: params.scheduledLoadingAt,
    scheduledDeliveryAt: params.scheduledDeliveryAt,
  );

  if (validationFailure != null) {
    return FailureResult<TripEntity>(validationFailure);
  }

  final duplicateVehicleFailure = await validateVehicleAvailability(
    repository: repository,
    companyId: context.companyId,
    tractorHeadId: optionalTripText(params.tractorHeadId),
    trailerId: optionalTripText(params.trailerId),
    excludingTripId: id,
  );

  if (duplicateVehicleFailure != null) {
    return FailureResult<TripEntity>(duplicateVehicleFailure);
  }

  final data = TripWriteData(
    companyId: context.companyId,
    customerId: params.customerId.trim(),
    routeId: params.routeId.trim(),
    driverId: optionalTripText(params.driverId),
    tractorHeadId: optionalTripText(params.tractorHeadId),
    trailerId: optionalTripText(params.trailerId),
    loadingOrderNumber: optionalTripText(params.loadingOrderNumber),
    waybillNumber: optionalTripText(params.waybillNumber),
    quantityTons: params.quantityTons,
    freightPrice: params.freightPrice,
    scheduledLoadingAt: params.scheduledLoadingAt,
    scheduledDeliveryAt: params.scheduledDeliveryAt,
    actualLoadingAt: params.actualLoadingAt,
    actualDeliveryAt: params.actualDeliveryAt,
    notes: optionalTripText(params.notes),
  );

  return repository.saveTrip(id: id, data: data, actorRole: context.role.value);
}
