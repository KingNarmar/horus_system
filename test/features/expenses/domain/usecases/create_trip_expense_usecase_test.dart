import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_funding_source.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_ledger_entry.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_ledger_write_data.dart';
import 'package:horus_system/features/expenses/domain/failures/expense_ledger_failure_codes.dart';
import 'package:horus_system/features/expenses/domain/repositories/expense_ledger_repository.dart';
import 'package:horus_system/features/expenses/domain/usecases/create_expense_ledger_entry_usecase.dart';
import 'package:horus_system/features/expenses/domain/usecases/create_trip_expense_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('CreateTripExpenseUseCase', () {
    test('parses exact amount and snapshots canonical type name', () async {
      final repository = _FakeRepository();
      final useCase = CreateTripExpenseUseCase(
        CreateExpenseLedgerEntryUseCase(repository),
      );

      final result = await useCase(_params(amountInput: '12.34'));

      expect(result, isA<Success<ExpenseLedgerEntry>>());
      expect(repository.data?.amount.minorUnits, 1234);
      expect(repository.data?.description, 'Fuel');
      expect(repository.data?.attribution.tripId, 'trip-1');
      expect(repository.data?.fundingSource, ExpenseFundingSource.company);
    });

    test('requires explicit description for Other', () async {
      final repository = _FakeRepository();
      final useCase = CreateTripExpenseUseCase(
        CreateExpenseLedgerEntryUseCase(repository),
      );

      final result = await useCase(
        _params(
          expenseType: _type(code: 'other', name: 'Other'),
          description: '   ',
        ),
      );

      expect(
        result.failureOrNull?.code,
        ExpenseLedgerFailureCodes.validationDescriptionRequired,
      );
      expect(repository.createCalls, 0);
    });

    test('trims explicit Other description and notes', () async {
      final repository = _FakeRepository();
      final useCase = CreateTripExpenseUseCase(
        CreateExpenseLedgerEntryUseCase(repository),
      );

      final result = await useCase(
        _params(
          expenseType: _type(code: 'other', name: 'Other'),
          description: '  Driver food  ',
          notes: '  receipt pending  ',
        ),
      );

      expect(result, isA<Success<ExpenseLedgerEntry>>());
      expect(repository.data?.description, 'Driver food');
      expect(repository.data?.notes, 'receipt pending');
    });

    test('rejects amount precision beyond company currency', () async {
      final repository = _FakeRepository();
      final useCase = CreateTripExpenseUseCase(
        CreateExpenseLedgerEntryUseCase(repository),
      );

      final result = await useCase(_params(amountInput: '1.234'));

      expect(
        result.failureOrNull?.code,
        ExpenseLedgerFailureCodes.validationAmountInvalid,
      );
      expect(repository.createCalls, 0);
    });

    test('rejects type from another company', () async {
      final repository = _FakeRepository();
      final useCase = CreateTripExpenseUseCase(
        CreateExpenseLedgerEntryUseCase(repository),
      );

      final result = await useCase(
        _params(expenseType: _type(companyId: 'company-2')),
      );

      expect(
        result.failureOrNull?.code,
        ExpenseLedgerFailureCodes.expenseTypeUnavailable,
      );
      expect(repository.createCalls, 0);
    });

    test('rejects inactive, noneligible, or codeless type', () async {
      for (final type in [
        _type(isActive: false),
        _type(isLedgerEligible: false),
        _type(code: null),
      ]) {
        final repository = _FakeRepository();
        final useCase = CreateTripExpenseUseCase(
          CreateExpenseLedgerEntryUseCase(repository),
        );
        final result = await useCase(_params(expenseType: type));
        expect(
          result.failureOrNull?.code,
          ExpenseLedgerFailureCodes.expenseTypeUnavailable,
        );
        expect(repository.createCalls, 0);
      }
    });
  });
}

CreateTripExpenseParams _params({
  ExpenseType? expenseType,
  String amountInput = '10.00',
  String? description,
  String? notes,
}) => CreateTripExpenseParams(
  currentCompanyContext: CurrentCompanyContext(
    company: const Company(
      id: 'company-1',
      name: 'Horus',
      baseCurrencyCode: 'AED',
      baseCurrencyFractionDigits: 2,
    ),
    role: CompanyRole.owner,
  ),
  tripId: 'trip-1',
  expenseType: expenseType ?? _type(),
  amountInput: amountInput,
  fundingSource: ExpenseFundingSource.company,
  expenseDate: BusinessDate(year: 2026, month: 9, day: 15),
  description: description,
  notes: notes,
);

ExpenseType _type({
  String companyId = 'company-1',
  String name = 'Fuel',
  String? code = 'fuel',
  bool isActive = true,
  bool isLedgerEligible = true,
}) => ExpenseType(
  id: 'type-1',
  companyId: companyId,
  name: name,
  code: code,
  isActive: isActive,
  isLedgerEligible: isLedgerEligible,
);

final class _FakeRepository implements ExpenseLedgerRepository {
  int createCalls = 0;
  ExpenseLedgerWriteData? data;

  @override
  Future<Result<ExpenseLedgerEntry>> createEntry(
    ExpenseLedgerWriteData data,
  ) async {
    createCalls++;
    this.data = data;
    return Success(
      ExpenseLedgerEntry(
        id: 'entry-1',
        companyId: data.companyId,
        expenseTypeId: data.expenseTypeId,
        amount: data.amount,
        currencyFractionDigits: data.currencyFractionDigits,
        expenseDate: data.expenseDate,
        fundingSource: data.fundingSource,
        attribution: data.attribution,
        description: data.description,
        notes: data.notes,
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
