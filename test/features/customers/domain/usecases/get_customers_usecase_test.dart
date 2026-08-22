import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/customers/domain/entities/customer.dart';
import 'package:horus_system/features/customers/domain/entities/customer_write_data.dart';
import 'package:horus_system/features/customers/domain/repositories/customers_repository.dart';
import 'package:horus_system/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('GetCustomersUseCase', () {
    test('checks permission before company id validation', () async {
      final repository = _FakeCustomersRepository();
      final useCase = GetCustomersUseCase(repository);

      final result = await useCase(
        GetCustomersParams(
          currentCompanyContext: _context(
            companyId: '   ',
            role: CompanyRole.driver,
          ),
        ),
      );

      expect(result, isA<FailureResult<List<Customer>>>());
      expect(result.failureOrNull?.code, FailureCodes.permissionCustomersView);
      expect(repository.getCustomersCalls, 0);
    });

    test('rejects blank company id without calling repository', () async {
      final repository = _FakeCustomersRepository();
      final useCase = GetCustomersUseCase(repository);

      final result = await useCase(
        GetCustomersParams(
          currentCompanyContext: _context(
            companyId: '   ',
            role: CompanyRole.owner,
          ),
        ),
      );

      expect(result, isA<FailureResult<List<Customer>>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationCompanyIdRequired,
      );
      expect(repository.getCustomersCalls, 0);
    });

    test('trims company id before repository call', () async {
      final repository = _FakeCustomersRepository();
      final useCase = GetCustomersUseCase(repository);

      final result = await useCase(
        GetCustomersParams(
          currentCompanyContext: _context(
            companyId: '  company-1  ',
            role: CompanyRole.viewer,
          ),
        ),
      );

      expect(result, isA<Success<List<Customer>>>());
      expect(repository.getCustomersCalls, 1);
      expect(repository.lastCompanyId, 'company-1');
    });
  });
}

CurrentCompanyContext _context({
  required String companyId,
  required CompanyRole role,
}) {
  return CurrentCompanyContext(
    company: Company(id: companyId, name: 'Company'),
    role: role,
  );
}

class _FakeCustomersRepository implements CustomersRepository {
  int getCustomersCalls = 0;
  String? lastCompanyId;

  @override
  Future<Result<List<Customer>>> getCustomers({
    required String companyId,
  }) async {
    getCustomersCalls += 1;
    lastCompanyId = companyId;
    return const Success<List<Customer>>([]);
  }

  @override
  Future<Result<Customer>> addCustomer({
    required CustomerWriteData data,
    required String actorRole,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Customer>> updateCustomer({
    required String customerId,
    required CustomerWriteData data,
    required String actorRole,
  }) {
    throw UnimplementedError();
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
}
