import 'package:horus_system/core/errors/failure_codes.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/customer.dart';
import '../policies/customers_permission_policy.dart';
import '../repositories/customers_repository.dart';

class ReactivateCustomerParams {
  final CurrentCompanyContext currentCompanyContext;
  final String customerId;

  const ReactivateCustomerParams({
    required this.currentCompanyContext,
    required this.customerId,
  });
}

class ReactivateCustomerUseCase
    implements UseCase<Customer, ReactivateCustomerParams> {
  final CustomersRepository _repository;

  const ReactivateCustomerUseCase(this._repository);

  @override
  Future<Result<Customer>> call(ReactivateCustomerParams params) {
    final context = params.currentCompanyContext;
    final normalizedCustomerId = params.customerId.trim();

    if (!CustomersPermissionPolicy.canManageCustomers(context.role)) {
      return Future.value(
        const FailureResult<Customer>(
          PermissionFailure(code: FailureCodes.permissionCustomersManagement, message: 'Customers management is not allowed.'),
        ),
      );
    }

    if (normalizedCustomerId.isEmpty) {
      return Future.value(
        const FailureResult<Customer>(
          ValidationFailure(code: FailureCodes.validationCustomerIdRequired, message: 'Customer id is required.'),
        ),
      );
    }

    return _repository.reactivateCustomer(
      companyId: context.companyId,
      customerId: normalizedCustomerId,
      actorRole: context.role.value,
    );
  }
}
