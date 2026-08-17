import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../entities/trip_entity.dart';
import '../entities/trip_status.dart';
import '../entities/trip_status_history.dart';
import '../policies/trips_permission_policy.dart';
import '../repositories/trips_repository.dart';
import 'trip_usecase_params.dart';
import 'trip_write_validation.dart';

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

    final id = optionalTripText(params.id);
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
      notes: optionalTripText(params.notes),
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

    final tripId = optionalTripText(params.tripId);
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
