import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver_settlement_driver_option.dart';
import '../policies/driver_settlements_permission_policy.dart';
import '../repositories/driver_settlements_repository.dart';

class GetDriverSettlementDriverOptionsParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetDriverSettlementDriverOptionsParams({
    required this.currentCompanyContext,
  });
}

class GetDriverSettlementDriverOptionsUseCase
    implements
        UseCase<
          List<DriverSettlementDriverOption>,
          GetDriverSettlementDriverOptionsParams
        > {
  final DriverSettlementsRepository _repository;

  const GetDriverSettlementDriverOptionsUseCase(this._repository);

  @override
  Future<Result<List<DriverSettlementDriverOption>>> call(
    GetDriverSettlementDriverOptionsParams params,
  ) {
    final context = params.currentCompanyContext;
    if (!DriverSettlementsPermissionPolicy.canViewDriverSettlements(
      context.role,
    )) {
      return Future.value(
        const FailureResult<List<DriverSettlementDriverOption>>(
          PermissionFailure(
            code: FailureCodes.permissionDriverSettlementsView,
            message: 'Driver settlements access is not allowed.',
          ),
        ),
      );
    }

    return _repository.getDriverOptions(companyId: context.companyId);
  }
}
