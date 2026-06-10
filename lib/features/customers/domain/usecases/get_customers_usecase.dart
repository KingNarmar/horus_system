import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/customer.dart';
import '../policies/customers_permission_policy.dart';
import '../repositories/customers_repository.dart';

class GetCustomersParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetCustomersParams({required this.currentCompanyContext});
}

class GetCustomersUseCase
    implements UseCase<List<Customer>, GetCustomersParams> {
  final CustomersRepository _repository;

  const GetCustomersUseCase(this._repository);

  @override
  Future<Result<List<Customer>>> call(GetCustomersParams params) {
    final currentContext = params.currentCompanyContext;

    if (!CustomersPermissionPolicy.canViewCustomers(currentContext.role)) {
      return Future.value(
        const FailureResult<List<Customer>>(
          PermissionFailure(message: 'Customers access is not allowed.'),
        ),
      );
    }

    return _repository.getCustomers(companyId: currentContext.companyId);
  }
}
