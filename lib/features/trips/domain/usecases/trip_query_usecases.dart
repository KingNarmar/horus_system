import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/trip_entity.dart';
import '../entities/trip_form_lookups.dart';
import '../policies/trips_permission_policy.dart';
import '../repositories/trips_repository.dart';
import 'trip_usecase_params.dart';
import 'trip_write_validation.dart';

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

    final id = optionalTripText(params.id);
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

class GetTripFormLookupsUseCase
    implements UseCase<TripFormLookups, GetTripFormLookupsParams> {
  final TripsRepository _repository;

  const GetTripFormLookupsUseCase(this._repository);

  @override
  Future<Result<TripFormLookups>> call(GetTripFormLookupsParams params) {
    final context = params.currentCompanyContext;

    if (!TripsPermissionPolicy.canManageTrips(context.role)) {
      return Future.value(
        const FailureResult<TripFormLookups>(
          PermissionFailure(
            code: FailureCodes.permissionTripsManagement,
            message: 'Trips management is not allowed.',
          ),
        ),
      );
    }

    return _repository.getTripFormLookups(companyId: context.companyId);
  }
}
