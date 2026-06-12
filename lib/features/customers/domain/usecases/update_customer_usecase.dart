import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/customer.dart';
import '../entities/customer_write_data.dart';
import '../policies/customers_permission_policy.dart';
import '../repositories/customers_repository.dart';

class UpdateCustomerParams {
  final CurrentCompanyContext currentCompanyContext;
  final String customerId;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? taxRegistrationNumber;
  final String? address;
  final String? city;
  final String? country;
  final double? creditLimit;

  const UpdateCustomerParams({
    required this.currentCompanyContext,
    required this.customerId,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.taxRegistrationNumber,
    this.address,
    this.city,
    this.country,
    this.creditLimit,
  });
}

class UpdateCustomerUseCase
    implements UseCase<Customer, UpdateCustomerParams> {
  final CustomersRepository _repository;

  const UpdateCustomerUseCase(this._repository);

  @override
  Future<Result<Customer>> call(UpdateCustomerParams params) {
    final context = params.currentCompanyContext;
    final normalizedCustomerId = params.customerId.trim();
    final normalizedName = params.name.trim();

    if (!CustomersPermissionPolicy.canManageCustomers(context.role)) {
      return Future.value(
        const FailureResult<Customer>(
          PermissionFailure(message: 'Customers management is not allowed.'),
        ),
      );
    }

    if (normalizedCustomerId.isEmpty) {
      return Future.value(
        const FailureResult<Customer>(
          ValidationFailure(message: 'Customer id is required.'),
        ),
      );
    }

    if (normalizedName.isEmpty) {
      return Future.value(
        const FailureResult<Customer>(
          ValidationFailure(message: 'Customer name is required.'),
        ),
      );
    }

    if (params.creditLimit != null && params.creditLimit! < 0) {
      return Future.value(
        const FailureResult<Customer>(
          ValidationFailure(message: 'Credit limit cannot be negative.'),
        ),
      );
    }

    return _repository.updateCustomer(
      customerId: normalizedCustomerId,
      actorRole: context.role.value,
      data: CustomerWriteData(
        companyId: context.companyId,
        name: normalizedName,
        contactPerson: _normalizeOptional(params.contactPerson),
        phone: _normalizeOptional(params.phone),
        email: _normalizeOptional(params.email),
        taxRegistrationNumber: _normalizeOptional(params.taxRegistrationNumber),
        address: _normalizeOptional(params.address),
        city: _normalizeOptional(params.city),
        country: _normalizeOptional(params.country),
        creditLimit: params.creditLimit,
      ),
    );
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
