import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/driver_settlement.dart';
import '../policies/driver_settlements_permission_policy.dart';
import '../repositories/driver_settlements_repository.dart';
import 'driver_settlement_params.dart';
import 'driver_settlement_usecase_validation.dart';

class GetDriverSettlementDetailsUseCase
    implements UseCase<DriverSettlement, GetDriverSettlementDetailsParams> {
  final DriverSettlementsRepository _repository;

  const GetDriverSettlementDetailsUseCase(this._repository);

  @override
  Future<Result<DriverSettlement>> call(
    GetDriverSettlementDetailsParams params,
  ) {
    final context = params.currentCompanyContext;
    if (!DriverSettlementsPermissionPolicy.canViewDriverSettlements(
      context.role,
    )) {
      return Future.value(
        const FailureResult<DriverSettlement>(
          PermissionFailure(
            code: FailureCodes.permissionDriverSettlementsView,
            message: 'Driver settlements access is not allowed.',
          ),
        ),
      );
    }

    final settlementId = DriverSettlementUseCaseValidation.optional(
      params.settlementId,
    );
    if (settlementId == null) {
      return Future.value(
        const FailureResult<DriverSettlement>(
          ValidationFailure(
            code: FailureCodes.validationDriverSettlementIdRequired,
            message: 'Driver settlement id is required.',
          ),
        ),
      );
    }

    return _repository.getDriverSettlementById(
      companyId: context.companyId,
      settlementId: settlementId,
    );
  }
}
