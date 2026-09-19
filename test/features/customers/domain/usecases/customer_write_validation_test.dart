import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/customers/domain/entities/customer.dart';
import 'package:horus_system/features/customers/domain/entities/customer_write_data.dart';
import 'package:horus_system/features/customers/domain/repositories/customers_repository.dart';
import 'package:horus_system/features/customers/domain/usecases/add_customer_usecase.dart';
import 'package:horus_system/features/customers/domain/usecases/update_customer_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('customer email validation', () {
    test(
      'add rejects malformed optional email before repository call',
      () async {
        final repository = _FakeCustomersRepository();
        final result = await AddCustomerUseCase(repository)(
          AddCustomerParams(
            currentCompanyContext: _context,
            name: 'Customer',
            email: 'invalid-email',
          ),
        );

        expect(result.failureOrNull?.code, FailureCodes.validationEmailInvalid);
        expect(repository.addCalls, 0);
      },
    );

    test(
      'update rejects malformed optional email before repository call',
      () async {
        final repository = _FakeCustomersRepository();
        final result = await UpdateCustomerUseCase(repository)(
          UpdateCustomerParams(
            currentCompanyContext: _context,
            customerId: 'customer-1',
            name: 'Customer',
            email: 'invalid-email',
          ),
        );

        expect(result.failureOrNull?.code, FailureCodes.validationEmailInvalid);
        expect(repository.updateCalls, 0);
      },
    );

    test('valid email is trimmed and forwarded by add', () async {
      final repository = _FakeCustomersRepository();
      final result = await AddCustomerUseCase(repository)(
        AddCustomerParams(
          currentCompanyContext: _context,
          name: 'Customer',
          email: '  user@example.com  ',
        ),
      );

      expect(result, isA<Success<Customer>>());
      expect(repository.lastWriteData?.email, 'user@example.com');
    });
  });
}

const _context = CurrentCompanyContext(
  company: Company(id: 'company-1', name: 'Company'),
  role: CompanyRole.owner,
);

class _FakeCustomersRepository implements CustomersRepository {
  int addCalls = 0;
  int updateCalls = 0;
  CustomerWriteData? lastWriteData;

  @override
  Future<Result<Customer>> addCustomer({
    required CustomerWriteData data,
    required String actorRole,
  }) async {
    addCalls++;
    lastWriteData = data;
    return Success(_customer(data));
  }

  @override
  Future<Result<Customer>> updateCustomer({
    required String customerId,
    required CustomerWriteData data,
    required String actorRole,
  }) async {
    updateCalls++;
    lastWriteData = data;
    return Success(_customer(data, id: customerId));
  }

  @override
  Future<Result<List<Customer>>> getCustomers({
    required String companyId,
  }) async {
    return const Success([]);
  }

  @override
  Future<Result<Customer>> deactivateCustomer({
    required String companyId,
    required String customerId,
    required String actorRole,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Customer>> reactivateCustomer({
    required String companyId,
    required String customerId,
    required String actorRole,
  }) {
    throw UnimplementedError();
  }

  Customer _customer(CustomerWriteData data, {String id = 'customer-1'}) {
    return Customer(
      id: id,
      companyId: data.companyId,
      name: data.name,
      email: data.email,
    );
  }
}
