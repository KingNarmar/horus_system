import '../../../../core/domain/services/company_business_date_provider.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../policies/driver_settlements_permission_policy.dart';
import 'driver_settlement_params.dart';

class GetDriverSettlementBusinessDateUseCase
    implements UseCase<BusinessDate, GetDriverSettlementBusinessDateParams> {
  final CompanyBusinessDateProvider _businessDateProvider;

  const GetDriverSettlementBusinessDateUseCase(this._businessDateProvider);

  @override
  Future<Result<BusinessDate>> call(
    GetDriverSettlementBusinessDateParams params,
  ) {
    final context = params.currentCompanyContext;
    if (!DriverSettlementsPermissionPolicy.canViewDriverSettlements(
      context.role,
    )) {
      return Future.value(
        const FailureResult<BusinessDate>(
          PermissionFailure(
            code: FailureCodes.permissionDriverSettlementsView,
            message: 'Driver settlements access is not allowed.',
          ),
        ),
      );
    }

    return _businessDateProvider.getBusinessDate(companyId: context.companyId);
  }
}
