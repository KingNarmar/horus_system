import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
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
import 'package:horus_system/features/expenses/domain/usecases/void_expense_ledger_entry_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('VoidExpenseLedgerEntryUseCase', () {
    test('voids same-company expense and trims the reason', () async {
      final repository = _FakeExpenseLedgerRepository();
      final result = await VoidExpenseLedgerEntryUseCase(repository)(
        VoidExpenseLedgerEntryParams(
          currentCompanyContext: _context(CompanyRole.owner),
          entry: _entry(),
          reason: '  duplicate  ',
        ),
      );

      expect(result, isA<Success<ExpenseLedgerEntry>>());
      expect(repository.voidCalls, 1);
      expect(repository.lastCompanyId, 'company-1');
      expect(repository.lastExpenseId, 'expense-1');
      expect(repository.lastReason, 'duplicate');
    });

    test('rejects cross-tenant entry before repository execution', () async {
      final repository = _FakeExpenseLedgerRepository();
      final result = await VoidExpenseLedgerEntryUseCase(repository)(
        VoidExpenseLedgerEntryParams(
          currentCompanyContext: _context(CompanyRole.owner),
          entry: _entry(companyId: 'company-2'),
        ),
      );

      expect(
        result.failureOrNull?.code,
        ExpenseLedgerFailureCodes.permissionManage,
      );
      expect(repository.voidCalls, 0);
    });

    test('denies operations for general expense', () async {
      final repository = _FakeExpenseLedgerRepository();
      final result = await VoidExpenseLedgerEntryUseCase(repository)(
        VoidExpenseLedgerEntryParams(
          currentCompanyContext: _context(CompanyRole.operations),
          entry: _entry(),
        ),
      );

      expect(
        result.failureOrNull?.code,
        ExpenseLedgerFailureCodes.permissionManage,
      );
      expect(repository.voidCalls, 0);
    });

    test('allows operations for trip-attributed expense', () async {
      final repository = _FakeExpenseLedgerRepository();
      final result = await VoidExpenseLedgerEntryUseCase(repository)(
        VoidExpenseLedgerEntryParams(
          currentCompanyContext: _context(CompanyRole.operations),
          entry: _entry(tripId: 'trip-1'),
        ),
      );

      expect(result, isA<Success<ExpenseLedgerEntry>>());
      expect(repository.voidCalls, 1);
    });

    test('rejects already voided entry before repository execution', () async {
      final repository = _FakeExpenseLedgerRepository();
      final result = await VoidExpenseLedgerEntryUseCase(repository)(
        VoidExpenseLedgerEntryParams(
          currentCompanyContext: _context(CompanyRole.owner),
          entry: _entry(isVoided: true),
        ),
      );

      expect(
        result.failureOrNull?.code,
        ExpenseLedgerFailureCodes.conflictAlreadyVoided,
      );
      expect(repository.voidCalls, 0);
    });
  });
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Horus'),
    role: role,
  );
}

ExpenseLedgerEntry _entry({
  String companyId = 'company-1',
  String? tripId,
  bool isVoided = false,
}) {
  final currency = CurrencyCode.tryParse('AED')!;
  return ExpenseLedgerEntry(
    id: 'expense-1',
    companyId: companyId,
    expenseTypeId: 'type-1',
    amount: Money(minorUnits: 1000, currency: currency),
    currencyFractionDigits: 2,
    expenseDate: BusinessDate(year: 2026, month: 9, day: 15),
    fundingSource: ExpenseFundingSource.company,
    attribution: ExpenseAttribution(tripId: tripId),
    isVoided: isVoided,
    voidedAt: isVoided ? DateTime.utc(2026, 9, 15) : null,
  );
}

final class _FakeExpenseLedgerRepository implements ExpenseLedgerRepository {
  int voidCalls = 0;
  String? lastCompanyId;
  String? lastExpenseId;
  String? lastReason;

  @override
  Future<Result<ExpenseLedgerEntry>> voidEntry({
    required String companyId,
    required String expenseId,
    String? reason,
  }) async {
    voidCalls++;
    lastCompanyId = companyId;
    lastExpenseId = expenseId;
    lastReason = reason;
    return Success(_entry(companyId: companyId, isVoided: true));
  }

  @override
  Future<Result<List<ExpenseLedgerEntry>>> getEntries({
    required String companyId,
    bool includeVoided = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ExpenseLedgerEntry>> createEntry(
    ExpenseLedgerWriteData data,
  ) {
    throw UnimplementedError();
  }
}
