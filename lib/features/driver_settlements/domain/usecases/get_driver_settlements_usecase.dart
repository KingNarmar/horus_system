import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/driver_settlement.dart';
import '../policies/driver_settlements_permission_policy.dart';
import '../repositories/driver_settlements_repository.dart';
import 'driver_settlement_params.dart';
import 'driver_settlement_usecase_validation.dart';

class GetDriverSettlementsUseCase
    implements UseCase<List<DriverSettlement>, GetDriverSettlementsParams> {
  final DriverSettlementsRepository _repository;

  const GetDriverSettlementsUseCase(this._repository);

  @override
  Future<Result<List<DriverSettlement>>> call(
    GetDriverSettlementsParams params,
  ) {
    final context = params.currentCompanyContext;
    if (!DriverSettlementsPermissionPolicy.canViewDriverSettlements(
      context.role,
    )) {
      return Future.value(
        const FailureResult<List<DriverSettlement>>(
          PermissionFailure(
            code: FailureCodes.permissionDriverSettlementsView,
            message: 'Driver settlements access is not allowed.',
          ),
        ),
      );
    }

    return _repository.getDriverSettlements(
      companyId: context.companyId,
      driverId: DriverSettlementUseCaseValidation.optional(params.driverId),
      includeVoided: params.includeVoided,
    );
  }
}
