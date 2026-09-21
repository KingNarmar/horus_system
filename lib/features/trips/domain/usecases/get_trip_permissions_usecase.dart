import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/trip_permissions.dart';
import '../policies/trips_permission_policy.dart';

class GetTripPermissionsParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetTripPermissionsParams({
    required this.currentCompanyContext,
  });
}

class GetTripPermissionsUseCase
    implements UseCase<TripPermissions, GetTripPermissionsParams> {
  const GetTripPermissionsUseCase();

  @override
  Future<Result<TripPermissions>> call(GetTripPermissionsParams params) {
    final role = params.currentCompanyContext.role;
    return Future.value(
      Success<TripPermissions>(
        TripPermissions(
          canManageTrips: TripsPermissionPolicy.canManageTrips(role),
          canUpdateTripStatus:
              TripsPermissionPolicy.canUpdateTripStatus(role),
          canManageTripDocuments:
              TripsPermissionPolicy.canManageTripDocuments(role),
          canViewTripFinancials:
              TripsPermissionPolicy.canViewTripFinancials(role),
        ),
      ),
    );
  }
}
