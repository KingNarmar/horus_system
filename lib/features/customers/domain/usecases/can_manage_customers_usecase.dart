import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../policies/customers_permission_policy.dart';

class CanManageCustomersParams {
  final CurrentCompanyContext currentCompanyContext;

  const CanManageCustomersParams({required this.currentCompanyContext});
}

class CanManageCustomersUseCase
    implements UseCase<bool, CanManageCustomersParams> {
  const CanManageCustomersUseCase();

  @override
  Future<Result<bool>> call(CanManageCustomersParams params) {
    return Future.value(
      Success<bool>(
        CustomersPermissionPolicy.canManageCustomers(
          params.currentCompanyContext.role,
        ),
      ),
    );
  }
}
