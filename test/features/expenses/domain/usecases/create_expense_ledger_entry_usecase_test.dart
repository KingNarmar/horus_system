import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_attribution.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_funding_source.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_ledger_entry.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_ledger_write_data.dart';
import 'package:horus_system/features/expenses/domain/failures/expense_ledger_failure_codes.dart';
import 'package:horus_system/features/expenses/domain/repositories/expense_ledger_repository.dart';
import 'package:horus_system/features/expenses/domain/usecases/create_expense_ledger_entry_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('CreateExpenseLedgerEntryUseCase', () {
    test('builds exact Money and preserves description', () async {
      final repository = _FakeExpenseLedgerRepository();
      final result = await CreateExpenseLedgerEntryUseCase(repository)(
        _params(amountMinorUnits: 12345, description: 'Fuel receipt'),
      );

      expect(result, isA<Success<ExpenseLedgerEntry>>());
      expect(repository.calls, 1);
      expect(repository.data?.companyId, 'company-1');
      expect(repository.data?.amount.minorUnits, 12345);
      expect(repository.data?.amount.currency.value, 'AED');
      expect(repository.data?.currencyFractionDigits, 2);
      expect(repository.data?.fundingSource, ExpenseFundingSource.company);
      expect(repository.data?.description, 'Fuel receipt');
    });

    test('rejects missing company financial configuration', () async {
      final repository = _FakeExpenseLedgerRepository();
      final result = await CreateExpenseLedgerEntryUseCase(repository)(
        _params(
          company: const Company(id: 'company-1', name: 'Horus'),
        ),
      );
      expect(
        result.failureOrNull?.code,
        ExpenseLedgerFailureCodes.financialConfigurationRequired,
      );
      expect(repository.calls, 0);
    });

    test('rejects non-positive amounts', () async {
      final repository = _FakeExpenseLedgerRepository();
      final result = await CreateExpenseLedgerEntryUseCase(repository)(
        _params(amountMinorUnits: 0),
      );
      expect(
        result.failureOrNull?.code,
        ExpenseLedgerFailureCodes.validationAmountInvalid,
      );
      expect(repository.calls, 0);
    });

    test('rejects trip combined with direct driver attribution', () async {
      final repository = _FakeExpenseLedgerRepository();
      final result = await CreateExpenseLedgerEntryUseCase(repository)(
        _params(
          attribution: const ExpenseAttribution(
            tripId: 'trip-1',
            driverId: 'driver-1',
          ),
        ),
      );
      expect(
        result.failureOrNull?.code,
        ExpenseLedgerFailureCodes.validationAttributionInvalid,
      );
      expect(repository.calls, 0);
    });

    test('denies operations for non-trip expense', () async {
      final repository = _FakeExpenseLedgerRepository();
      final result = await CreateExpenseLedgerEntryUseCase(repository)(
        _params(role: CompanyRole.operations),
      );
      expect(
        result.failureOrNull?.code,
        ExpenseLedgerFailureCodes.permissionManage,
      );
      expect(repository.calls, 0);
    });

    test('allows operations for trip-attributed expense', () async {
      final repository = _FakeExpenseLedgerRepository();
      final result = await CreateExpenseLedgerEntryUseCase(repository)(
        _params(
          role: CompanyRole.operations,
          attribution: const ExpenseAttribution(tripId: 'trip-1'),
        ),
      );
      expect(result, isA<Success<ExpenseLedgerEntry>>());
      expect(repository.calls, 1);
      expect(repository.data?.attribution.tripId, 'trip-1');
    });
  });
}

CreateExpenseLedgerEntryParams _params({
  CompanyRole role = CompanyRole.owner,
  Company company = const Company(
    id: 'company-1',
    name: 'Horus',
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
  ),
  int amountMinorUnits = 1000,
  ExpenseAttribution attribution = const ExpenseAttribution(),
  String? description,
}) => CreateExpenseLedgerEntryParams(
  currentCompanyContext: CurrentCompanyContext(company: company, role: role),
  expenseTypeId: 'expense-type-1',
  amountMinorUnits: amountMinorUnits,
  expenseDate: BusinessDate(year: 2026, month: 9, day: 15),
  attribution: attribution,
  description: description,
);

final class _FakeExpenseLedgerRepository implements ExpenseLedgerRepository {
  int calls = 0;
  ExpenseLedgerWriteData? data;

  @override
  Future<Result<ExpenseLedgerEntry>> createEntry(
    ExpenseLedgerWriteData data,
  ) async {
    calls++;
    this.data = data;
    return Success(
      ExpenseLedgerEntry(
        id: 'expense-1',
        companyId: data.companyId,
        expenseTypeId: data.expenseTypeId,
        amount: data.amount,
        currencyFractionDigits: data.currencyFractionDigits,
        expenseDate: data.expenseDate,
        fundingSource: data.fundingSource,
        attribution: data.attribution,
        description: data.description,
        isVoided: false,
      ),
    );
  }

  @override
  Future<Result<List<ExpenseLedgerEntry>>> getEntries({
    required String companyId,
    bool includeVoided = false,
  }) async => const Success([]);

  @override
  Future<Result<List<ExpenseLedgerEntry>>> getEntriesForTrip({
    required String companyId,
    required String tripId,
    bool includeVoided = false,
  }) async => const Success([]);

  @override
  Future<Result<ExpenseLedgerEntry>> voidEntry({
    required String companyId,
    required String expenseId,
    String? reason,
  }) {
    throw UnimplementedError();
  }
}
