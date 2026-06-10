import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/customer.dart';
import '../entities/customer_write_data.dart';
import '../policies/customers_permission_policy.dart';
import '../repositories/customers_repository.dart';

class AddCustomerParams {
  final CurrentCompanyContext currentCompanyContext;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? taxRegistrationNumber;
  final String? address;
  final String? city;
  final String? country;
  final double? creditLimit;

  const AddCustomerParams({
    required this.currentCompanyContext,
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

class AddCustomerUseCase implements UseCase<Customer, AddCustomerParams> {
  final CustomersRepository _repository;

  const AddCustomerUseCase(this._repository);

  @override
  Future<Result<Customer>> call(AddCustomerParams params) {
    final context = params.currentCompanyContext;

    if (!CustomersPermissionPolicy.canManageCustomers(context.role)) {
      return Future.value(
        const FailureResult<Customer>(
          PermissionFailure(message: 'Customers management is not allowed.'),
        ),
      );
    }

    final normalizedName = params.name.trim();

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

    return _repository.addCustomer(
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
