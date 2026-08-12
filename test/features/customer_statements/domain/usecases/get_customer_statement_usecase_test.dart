import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/customer_statements/domain/entities/customer_statement_source.dart';
import 'package:horus_system/features/customer_statements/domain/failures/customer_statement_failure_codes.dart';
import 'package:horus_system/features/customer_statements/domain/repositories/customer_statements_repository.dart';
import 'package:horus_system/features/customer_statements/domain/usecases/customer_statement_params.dart';
import 'package:horus_system/features/customer_statements/domain/usecases/get_customer_statement_usecase.dart';
import 'package:test/test.dart';

void main() {
  test('accountant delegates company-scoped customer and dates', () async {
    final repository = _FakeRepository();
    final useCase = GetCustomerStatementUseCase(repository: repository);

    final result = await useCase(
      GetCustomerStatementParams(
        currentCompanyContext: _context(CompanyRole.accountant),
        customerId: ' customer-1 ',
        fromDate: DateTime(2026, 8, 1, 18),
        toDate: DateTime(2026, 8, 31, 23),
      ),
    );

    expect(result.failureOrNull, isNull);
    expect(repository.lastCompanyId, 'company-1');
    expect(repository.lastCustomerId, 'customer-1');
    expect(repository.lastFromDate, DateTime(2026, 8, 1));
    expect(repository.lastToDate, DateTime(2026, 8, 31));
  });

  test('owner can view statements', () async {
    final repository = _FakeRepository();
    final useCase = GetCustomerStatementUseCase(repository: repository);

    final result = await useCase(
      GetCustomerStatementParams(
        currentCompanyContext: _context(CompanyRole.owner),
        customerId: 'customer-1',
      ),
    );

    expect(result.failureOrNull, isNull);
    expect(repository.lastCompanyId, 'company-1');
  });

  test('driver is denied before repository access', () async {
    final repository = _FakeRepository();
    final useCase = GetCustomerStatementUseCase(repository: repository);

    final result = await useCase(
      GetCustomerStatementParams(
        currentCompanyContext: _context(CompanyRole.driver),
        customerId: 'customer-1',
      ),
    );

    expect(
      result.failureOrNull?.code,
      CustomerStatementFailureCodes.permissionView,
    );
    expect(repository.lastCompanyId, isNull);
  });

  test('rejects empty customer id', () async {
    final useCase = GetCustomerStatementUseCase(
      repository: _FakeRepository(),
    );

    final result = await useCase(
      GetCustomerStatementParams(
        currentCompanyContext: _context(CompanyRole.viewer),
        customerId: ' ',
      ),
    );

    expect(
      result.failureOrNull?.code,
      CustomerStatementFailureCodes.validationCustomerIdRequired,
    );
  });

  test('rejects from date after to date before repository access', () async {
    final repository = _FakeRepository();
    final useCase = GetCustomerStatementUseCase(repository: repository);

    final result = await useCase(
      GetCustomerStatementParams(
        currentCompanyContext: _context(CompanyRole.owner),
        customerId: 'customer-1',
        fromDate: DateTime(2026, 8, 11),
        toDate: DateTime(2026, 8, 10),
      ),
    );

    expect(
      result.failureOrNull?.code,
      CustomerStatementFailureCodes.validationDateRange,
    );
    expect(repository.lastCompanyId, isNull);
  });

  test('rejects invalid configured currency code', () async {
    final repository = _FakeRepository();
    final useCase = GetCustomerStatementUseCase(repository: repository);
    final context = CurrentCompanyContext(
      company: const Company(
        id: 'company-1',
        name: 'Company',
        baseCurrencyCode: 'A',
        baseCurrencyFractionDigits: 2,
        businessTimezone: 'Asia/Dubai',
      ),
      role: CompanyRole.owner,
    );

    final result = await useCase(
      GetCustomerStatementParams(
        currentCompanyContext: context,
        customerId: 'customer-1',
      ),
    );

    expect(
      result.failureOrNull?.code,
      CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
    );
    expect(repository.lastCompanyId, isNull);
  });

  test('requires complete company regional settings', () async {
    final repository = _FakeRepository();
    final useCase = GetCustomerStatementUseCase(repository: repository);
    final context = CurrentCompanyContext(
      company: const Company(id: 'company-1', name: 'Company'),
      role: CompanyRole.owner,
    );

    final result = await useCase(
      GetCustomerStatementParams(
        currentCompanyContext: context,
        customerId: 'customer-1',
      ),
    );

    expect(
      result.failureOrNull?.code,
      CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
    );
    expect(repository.lastCompanyId, isNull);
  });
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(
      id: 'company-1',
      name: 'Company',
      baseCurrencyCode: 'AED',
      baseCurrencyFractionDigits: 2,
      businessTimezone: 'Asia/Dubai',
    ),
    role: role,
  );
}

final class _FakeRepository implements CustomerStatementsRepository {
  String? lastCompanyId;
  String? lastCustomerId;
  DateTime? lastFromDate;
  DateTime? lastToDate;

  @override
  Future<Result<CustomerStatementSource>> getStatementSource({
    required String companyId,
    required String customerId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    lastCompanyId = companyId;
    lastCustomerId = customerId;
    lastFromDate = fromDate;
    lastToDate = toDate;
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
