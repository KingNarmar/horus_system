import 'package:horus_system/core/errors/failure_codes.dart';

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
          PermissionFailure(
            code: FailureCodes.permissionCustomersView,
            message: 'Customers access is not allowed.',
          ),
        ),
      );
    }

    final companyId = currentContext.companyId.trim();
    if (companyId.isEmpty) {
      return Future.value(
        const FailureResult<List<Customer>>(
          ValidationFailure(
            code: FailureCodes.validationCompanyIdRequired,
            message: 'Company id is required.',
          ),
        ),
      );
    }

    return _repository.getCustomers(companyId: companyId);
  }
}
