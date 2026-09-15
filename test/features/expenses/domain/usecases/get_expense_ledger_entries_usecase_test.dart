import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_ledger_entry.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_ledger_write_data.dart';
import 'package:horus_system/features/expenses/domain/failures/expense_ledger_failure_codes.dart';
import 'package:horus_system/features/expenses/domain/repositories/expense_ledger_repository.dart';
import 'package:horus_system/features/expenses/domain/usecases/get_expense_ledger_entries_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('GetExpenseLedgerEntriesUseCase', () {
    test('scopes reads to current company and forwards void filter', () async {
      final repository = _FakeExpenseLedgerRepository();
      final result = await GetExpenseLedgerEntriesUseCase(repository)(
        GetExpenseLedgerEntriesParams(
          currentCompanyContext: _context(CompanyRole.viewer),
          includeVoided: true,
        ),
      );
      expect(result, isA<Success<List<ExpenseLedgerEntry>>>());
      expect(repository.getCalls, 1);
      expect(repository.lastCompanyId, 'company-1');
      expect(repository.lastIncludeVoided, isTrue);
    });

    test('denies driver read access before repository execution', () async {
      final repository = _FakeExpenseLedgerRepository();
      final result = await GetExpenseLedgerEntriesUseCase(repository)(
        GetExpenseLedgerEntriesParams(
          currentCompanyContext: _context(CompanyRole.driver),
        ),
      );
      expect(
        result.failureOrNull?.code,
        ExpenseLedgerFailureCodes.permissionView,
      );
      expect(repository.getCalls, 0);
    });
  });
}

CurrentCompanyContext _context(CompanyRole role) => CurrentCompanyContext(
  company: const Company(id: 'company-1', name: 'Horus'),
  role: role,
);

final class _FakeExpenseLedgerRepository implements ExpenseLedgerRepository {
  int getCalls = 0;
  String? lastCompanyId;
  bool? lastIncludeVoided;

  @override
  Future<Result<List<ExpenseLedgerEntry>>> getEntries({
    required String companyId,
    bool includeVoided = false,
  }) async {
    getCalls++;
    lastCompanyId = companyId;
    lastIncludeVoided = includeVoided;
    return const Success([]);
  }

  @override
  Future<Result<List<ExpenseLedgerEntry>>> getEntriesForTrip({
    required String companyId,
    required String tripId,
    bool includeVoided = false,
  }) async => const Success([]);

  @override
  Future<Result<ExpenseLedgerEntry>> createEntry(ExpenseLedgerWriteData data) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ExpenseLedgerEntry>> voidEntry({
    required String companyId,
    required String expenseId,
    String? reason,
  }) {
    throw UnimplementedError();
  }
}
