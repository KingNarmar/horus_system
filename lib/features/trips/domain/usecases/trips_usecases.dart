import 'package:horus_system/core/errors/failure.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/trip_entity.dart';
import '../entities/trip_status.dart';
import '../entities/trip_status_history.dart';
import '../entities/trip_write_data.dart';
import '../policies/trips_permission_policy.dart';
import '../repositories/trips_repository.dart';

class GetTripsParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetTripsParams({required this.currentCompanyContext});
}

class GetTripDetailsParams {
  final CurrentCompanyContext currentCompanyContext;
  final String id;

  const GetTripDetailsParams({
    required this.currentCompanyContext,
    required this.id,
  });
}

class CreateTripParams {
  final CurrentCompanyContext currentCompanyContext;
  final String customerId;
  final String routeId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final double? quantityTons;
  final double? freightPrice;
  final DateTime? scheduledLoadingAt;
  final DateTime? scheduledDeliveryAt;
  final DateTime? actualLoadingAt;
  final DateTime? actualDeliveryAt;
  final String? notes;

  const CreateTripParams({
    required this.currentCompanyContext,
    required this.customerId,
    required this.routeId,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.loadingOrderNumber,
    this.waybillNumber,
    this.quantityTons,
    this.freightPrice,
    this.scheduledLoadingAt,
    this.scheduledDeliveryAt,
    this.actualLoadingAt,
    this.actualDeliveryAt,
    this.notes,
  });
}

class SaveTripParams {
  final CurrentCompanyContext currentCompanyContext;
  final String id;
  final String customerId;
  final String routeId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final double? quantityTons;
  final double? freightPrice;
  final DateTime? scheduledLoadingAt;
  final DateTime? scheduledDeliveryAt;
  final DateTime? actualLoadingAt;
  final DateTime? actualDeliveryAt;
  final String? notes;

  const SaveTripParams({
    required this.currentCompanyContext,
    required this.id,
    required this.customerId,
    required this.routeId,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.loadingOrderNumber,
    this.waybillNumber,
    this.quantityTons,
    this.freightPrice,
    this.scheduledLoadingAt,
    this.scheduledDeliveryAt,
    this.actualLoadingAt,
    this.actualDeliveryAt,
    this.notes,
  });
}

class UpdateTripStatusParams {
  final CurrentCompanyContext currentCompanyContext;
  final String id;
  final TripStatus newStatus;
  final String? notes;

  const UpdateTripStatusParams({
    required this.currentCompanyContext,
    required this.id,
    required this.newStatus,
    this.notes,
  });
}

class GetTripStatusHistoryParams {
  final CurrentCompanyContext currentCompanyContext;
  final String tripId;

  const GetTripStatusHistoryParams({
    required this.currentCompanyContext,
    required this.tripId,
  });
}

class CalculateTripNetProfitParams {
  final double? freightPrice;
  final double? totalExpenses;

  const CalculateTripNetProfitParams({
    required this.freightPrice,
    required this.totalExpenses,
  });
}

class GetTripsUseCase implements UseCase<List<TripEntity>, GetTripsParams> {
  final TripsRepository _repository;

  const GetTripsUseCase(this._repository);

  @override
  Future<Result<List<TripEntity>>> call(GetTripsParams params) {
    final context = params.currentCompanyContext;

    if (!TripsPermissionPolicy.canViewTrips(context.role)) {
      return Future.value(
        const FailureResult<List<TripEntity>>(
          PermissionFailure(
            code: FailureCodes.permissionTripsView,
            message: 'Trips access is not allowed.',
          ),
        ),
      );
    }

    return _repository.getTrips(companyId: context.companyId);
  }
}

class GetTripDetailsUseCase
    implements UseCase<TripEntity, GetTripDetailsParams> {
  final TripsRepository _repository;

  const GetTripDetailsUseCase(this._repository);

  @override
  Future<Result<TripEntity>> call(GetTripDetailsParams params) {
    final context = params.currentCompanyContext;

    if (!TripsPermissionPolicy.canViewTrips(context.role)) {
      return Future.value(
        const FailureResult<TripEntity>(
          PermissionFailure(
            code: FailureCodes.permissionTripsView,
            message: 'Trips access is not allowed.',
          ),
        ),
      );
    }

    final id = _optional(params.id);
    if (id == null) {
      return Future.value(
        const FailureResult<TripEntity>(
          ValidationFailure(
            code: FailureCodes.validationTripIdRequired,
            message: 'Trip id is required.',
          ),
        ),
      );
    }

    return _repository.getTripDetails(companyId: context.companyId, id: id);
  }
}

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

class UpdateTripStatusUseCase
    implements UseCase<TripEntity, UpdateTripStatusParams> {
  final TripsRepository _repository;

  const UpdateTripStatusUseCase(this._repository);

  @override
  Future<Result<TripEntity>> call(UpdateTripStatusParams params) async {
    final context = params.currentCompanyContext;

    if (!TripsPermissionPolicy.canUpdateTripStatus(context.role)) {
      return const FailureResult<TripEntity>(
        PermissionFailure(
          code: FailureCodes.permissionTripStatusUpdate,
          message: 'Trip status update is not allowed.',
        ),
      );
    }

    final id = _optional(params.id);
    if (id == null) {
      return const FailureResult<TripEntity>(
        ValidationFailure(
          code: FailureCodes.validationTripIdRequired,
          message: 'Trip id is required.',
        ),
      );
    }

    final currentTripResult = await _repository.getTripDetails(
      companyId: context.companyId,
      id: id,
    );

    if (currentTripResult is FailureResult<TripEntity>) {
      return FailureResult<TripEntity>(currentTripResult.failure);
    }

    final currentTrip = (currentTripResult as Success<TripEntity>).data;

    if (!currentTrip.status.canMoveTo(params.newStatus)) {
      return const FailureResult<TripEntity>(
        ValidationFailure(
          code: FailureCodes.validationTripStatusTransitionInvalid,
          message: 'Trip status transition is not allowed.',
        ),
      );
    }

    return _repository.updateTripStatus(
      companyId: context.companyId,
      id: id,
      newStatus: params.newStatus,
      actorRole: context.role.value,
      notes: _optional(params.notes),
    );
  }
}

class GetTripStatusHistoryUseCase
    implements UseCase<List<TripStatusHistory>, GetTripStatusHistoryParams> {
  final TripsRepository _repository;

  const GetTripStatusHistoryUseCase(this._repository);

  @override
  Future<Result<List<TripStatusHistory>>> call(
    GetTripStatusHistoryParams params,
  ) {
    final context = params.currentCompanyContext;

    if (!TripsPermissionPolicy.canViewTrips(context.role)) {
      return Future.value(
        const FailureResult<List<TripStatusHistory>>(
          PermissionFailure(
            code: FailureCodes.permissionTripsView,
            message: 'Trips access is not allowed.',
          ),
        ),
      );
    }

    final tripId = _optional(params.tripId);
    if (tripId == null) {
      return Future.value(
        const FailureResult<List<TripStatusHistory>>(
          ValidationFailure(
            code: FailureCodes.validationTripIdRequired,
            message: 'Trip id is required.',
          ),
        ),
      );
    }

    return _repository.getTripStatusHistory(
      companyId: context.companyId,
      tripId: tripId,
    );
  }
}

class CalculateTripNetProfitUseCase
    implements UseCase<double, CalculateTripNetProfitParams> {
  const CalculateTripNetProfitUseCase();

  @override
  Future<Result<double>> call(CalculateTripNetProfitParams params) {
    final freightPrice = params.freightPrice ?? 0;
    final totalExpenses = params.totalExpenses ?? 0;

    if (freightPrice < 0) {
      return Future.value(
        const FailureResult<double>(
          ValidationFailure(
            code: FailureCodes.validationTripFreightPriceNegative,
            message: 'Freight price cannot be negative.',
          ),
        ),
      );
    }

    if (totalExpenses < 0) {
      return Future.value(
        const FailureResult<double>(
          ValidationFailure(
            code: FailureCodes.validationTripExpensesNegative,
            message: 'Trip expenses cannot be negative.',
          ),
        ),
      );
    }

    return Future.value(Success<double>(freightPrice - totalExpenses));
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

  final validationFailure = _validateTripWriteData(
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

  final duplicateVehicleFailure = await _validateVehicleAvailability(
    repository: repository,
    companyId: context.companyId,
    tractorHeadId: _optional(params.tractorHeadId),
    trailerId: _optional(params.trailerId),
  );

  if (duplicateVehicleFailure != null) {
    return FailureResult<TripEntity>(duplicateVehicleFailure);
  }

  final data = TripWriteData(
    companyId: context.companyId,
    customerId: params.customerId.trim(),
    routeId: params.routeId.trim(),
    driverId: _optional(params.driverId),
    tractorHeadId: _optional(params.tractorHeadId),
    trailerId: _optional(params.trailerId),
    loadingOrderNumber: _optional(params.loadingOrderNumber),
    waybillNumber: _optional(params.waybillNumber),
    quantityTons: params.quantityTons,
    freightPrice: params.freightPrice,
    scheduledLoadingAt: params.scheduledLoadingAt,
    scheduledDeliveryAt: params.scheduledDeliveryAt,
    actualLoadingAt: params.actualLoadingAt,
    actualDeliveryAt: params.actualDeliveryAt,
    notes: _optional(params.notes),
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

  final id = _optional(params.id);
  if (id == null) {
    return const FailureResult<TripEntity>(
      ValidationFailure(
        code: FailureCodes.validationTripIdRequired,
        message: 'Trip id is required.',
      ),
    );
  }

  final validationFailure = _validateTripWriteData(
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

  final duplicateVehicleFailure = await _validateVehicleAvailability(
    repository: repository,
    companyId: context.companyId,
    tractorHeadId: _optional(params.tractorHeadId),
    trailerId: _optional(params.trailerId),
    excludingTripId: id,
  );

  if (duplicateVehicleFailure != null) {
    return FailureResult<TripEntity>(duplicateVehicleFailure);
  }

  final data = TripWriteData(
    companyId: context.companyId,
    customerId: params.customerId.trim(),
    routeId: params.routeId.trim(),
    driverId: _optional(params.driverId),
    tractorHeadId: _optional(params.tractorHeadId),
    trailerId: _optional(params.trailerId),
    loadingOrderNumber: _optional(params.loadingOrderNumber),
    waybillNumber: _optional(params.waybillNumber),
    quantityTons: params.quantityTons,
    freightPrice: params.freightPrice,
    scheduledLoadingAt: params.scheduledLoadingAt,
    scheduledDeliveryAt: params.scheduledDeliveryAt,
    actualLoadingAt: params.actualLoadingAt,
    actualDeliveryAt: params.actualDeliveryAt,
    notes: _optional(params.notes),
  );

  return repository.saveTrip(id: id, data: data, actorRole: context.role.value);
}

Failure? _validateTripWriteData({
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

Future<Failure?> _validateVehicleAvailability({
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

String? _optional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
