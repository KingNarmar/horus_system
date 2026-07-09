import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/driver_settlement.dart';
import '../entities/driver_settlement_write_data.dart';
import '../policies/driver_settlements_permission_policy.dart';
import '../repositories/driver_settlements_repository.dart';
import 'driver_settlement_params.dart';
import 'driver_settlement_usecase_validation.dart';

class FinalizeDriverSettlementUseCase
    implements UseCase<DriverSettlement, FinalizeDriverSettlementParams> {
  final DriverSettlementsRepository _repository;

  const FinalizeDriverSettlementUseCase(this._repository);

  @override
  Future<Result<DriverSettlement>> call(FinalizeDriverSettlementParams params) {
    final context = params.currentCompanyContext;
    if (!DriverSettlementsPermissionPolicy.canFinalizeDriverSettlements(
      context.role,
    )) {
      return Future.value(
        const FailureResult<DriverSettlement>(
          PermissionFailure(
            code: FailureCodes.permissionDriverSettlementsManagement,
            message: 'Driver settlements management is not allowed.',
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

    return _repository.finalizeSettlement(
      actorRole: context.role.name,
      data: DriverSettlementFinalizeData(
        companyId: context.companyId,
        settlementId: settlementId,
      ),
    );
  }
}
