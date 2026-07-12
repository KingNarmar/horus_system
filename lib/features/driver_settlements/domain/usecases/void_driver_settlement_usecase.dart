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

class VoidDriverSettlementUseCase
    implements UseCase<DriverSettlement, VoidDriverSettlementParams> {
  final DriverSettlementsRepository _repository;

  const VoidDriverSettlementUseCase(this._repository);

  @override
  Future<Result<DriverSettlement>> call(VoidDriverSettlementParams params) {
    final context = params.currentCompanyContext;
    if (!DriverSettlementsPermissionPolicy.canVoidDriverSettlements(
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

    final reason = DriverSettlementUseCaseValidation.optional(params.reason);
    if (reason == null) {
      return Future.value(
        const FailureResult<DriverSettlement>(
          ValidationFailure(
            code: FailureCodes.validationDriverSettlementVoidReasonRequired,
            message: 'Driver settlement void reason is required.',
          ),
        ),
      );
    }

    return _repository.voidSettlement(
      actorRole: context.role.name,
      data: DriverSettlementVoidData(
        companyId: context.companyId,
        settlementId: settlementId,
        reason: reason,
      ),
    );
  }
}
