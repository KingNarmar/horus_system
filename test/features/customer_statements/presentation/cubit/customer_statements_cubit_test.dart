import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/customer_statements/domain/entities/customer_statement_source.dart';
import 'package:horus_system/features/customer_statements/domain/repositories/customer_statements_repository.dart';
import 'package:horus_system/features/customer_statements/domain/usecases/get_customer_statement_usecase.dart';
import 'package:horus_system/features/customer_statements/presentation/cubit/customer_statements_cubit.dart';
import 'package:horus_system/features/customer_statements/presentation/cubit/customer_statements_state.dart';
import 'package:horus_system/features/customers/domain/entities/customer.dart';
import 'package:horus_system/features/customers/domain/entities/customer_write_data.dart';
import 'package:horus_system/features/customers/domain/repositories/customers_repository.dart';
import 'package:horus_system/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:test/test.dart';

void main() {
  test('loads company customers and starts with no selection', () async {
    final customersRepository = _FakeCustomersRepository();
    final cubit = _cubit(customersRepository);

    await cubit.load(_context);

    final state = cubit.state as CustomerStatementsReady;
    expect(state.customers, hasLength(2));
    expect(state.selectedCustomerId, isNull);
    expect(state.canApply, isFalse);
    expect(customersRepository.lastCompanyId, 'company-1');
    await cubit.close();
  });

  test('rejects selecting customer outside loaded company list', () async {
    final cubit = _cubit(_FakeCustomersRepository());
    await cubit.load(_context);

    cubit.selectCustomer('foreign-customer');

    final state = cubit.state as CustomerStatementsReady;
    expect(state.selectedCustomerId, isNull);
    expect(state.canApply, isFalse);
    await cubit.close();
  });

  test(
    'inactive customer remains selectable for historical statements',
    () async {
      final cubit = _cubit(_FakeCustomersRepository());
      await cubit.load(_context);

      cubit.selectCustomer('customer-2');

      final state = cubit.state as CustomerStatementsReady;
      expect(state.selectedCustomer?.isActive, isFalse);
      expect(state.canApply, isTrue);
      await cubit.close();
    },
  );

  test('valid customer enables apply and statement loads', () async {
    final statementRepository = _FakeStatementRepository();
    final cubit = _cubit(
      _FakeCustomersRepository(),
      statementRepository: statementRepository,
    );
    await cubit.load(_context);

    cubit.selectCustomer('customer-1');
    expect((cubit.state as CustomerStatementsReady).canApply, isTrue);

    await cubit.apply();

    final state = cubit.state as CustomerStatementsReady;
    expect(state.statement?.customerId, 'customer-1');
    expect(statementRepository.lastCompanyId, 'company-1');
    expect(statementRepository.lastCustomerId, 'customer-1');
    await cubit.close();
  });

  test('changing date invalidates previously loaded statement', () async {
    final cubit = _cubit(_FakeCustomersRepository());
    await cubit.load(_context);
    cubit.selectCustomer('customer-1');
    await cubit.apply();

    cubit.setFromDate(DateTime(2026, 8, 10, 18));

    final state = cubit.state as CustomerStatementsReady;
    expect(state.fromDate, DateTime(2026, 8, 10));
    expect(state.statement, isNull);
    await cubit.close();
  });

  test('clear dates preserves customer selection', () async {
    final cubit = _cubit(_FakeCustomersRepository());
    await cubit.load(_context);
    cubit.selectCustomer('customer-1');
    cubit.setFromDate(DateTime(2026, 8, 1));
    cubit.setToDate(DateTime(2026, 8, 31));

    cubit.clearDates();

    final state = cubit.state as CustomerStatementsReady;
    expect(state.selectedCustomerId, 'customer-1');
    expect(state.fromDate, isNull);
    expect(state.toDate, isNull);
    await cubit.close();
  });
}

CustomerStatementsCubit _cubit(
  _FakeCustomersRepository customers, {
  _FakeStatementRepository? statementRepository,
}) {
  return CustomerStatementsCubit(
    getCustomersUseCase: GetCustomersUseCase(customers),
    getCustomerStatementUseCase: GetCustomerStatementUseCase(
      repository: statementRepository ?? _FakeStatementRepository(),
    ),
  );
}

const _context = CurrentCompanyContext(
  company: Company(
    id: 'company-1',
    name: 'Company',
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'Asia/Dubai',
  ),
  role: CompanyRole.accountant,
);

final class _FakeCustomersRepository implements CustomersRepository {
  String? lastCompanyId;

  @override
  Future<Result<List<Customer>>> getCustomers({
    required String companyId,
  }) async {
    lastCompanyId = companyId;
    return const Success([
      Customer(id: 'customer-1', companyId: 'company-1', name: 'Active'),
      Customer(
        id: 'customer-2',
        companyId: 'company-1',
        name: 'Inactive',
        isActive: false,
      ),
    ]);
  }

  @override
  Future<Result<Customer>> addCustomer({
    required CustomerWriteData data,
    required String actorRole,
  }) => throw UnimplementedError();

  @override
  Future<Result<Customer>> updateCustomer({
    required String customerId,
    required CustomerWriteData data,
    required String actorRole,
  }) => throw UnimplementedError();

  @override
  Future<Result<Customer>> deactivateCustomer({
    required String companyId,
    required String customerId,
    required String actorRole,
  }) => throw UnimplementedError();

  @override
  Future<Result<Customer>> reactivateCustomer({
    required String companyId,
    required String customerId,
    required String actorRole,
  }) => throw UnimplementedError();
}

final class _FakeStatementRepository implements CustomerStatementsRepository {
  String? lastCompanyId;
  String? lastCustomerId;

  @override
  Future<Result<CustomerStatementSource>> getStatementSource({
    required String companyId,
    required String customerId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    lastCompanyId = companyId;
    lastCustomerId = customerId;
    final currency = CurrencyCode.tryParse('AED')!;
    return Success(
      CustomerStatementSource(
        companyId: companyId,
        customerId: customerId,
        customerName: 'Customer',
        customerIsActive: true,
        baseCurrency: currency,
        baseCurrencyFractionDigits: 2,
        businessTimezone: 'Asia/Dubai',
        fromDate: fromDate,
        toDate: toDate,
        openingInvoiceAmounts: const [],
        openingPaymentAmounts: const [],
        movements: const [],
      ),
    );
  }
}
