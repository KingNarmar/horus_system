import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_ledger_entry.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_ledger_write_data.dart';
import 'package:horus_system/features/expenses/domain/failures/expense_ledger_failure_codes.dart';
import 'package:horus_system/features/expenses/domain/repositories/expense_ledger_repository.dart';
import 'package:horus_system/features/expenses/domain/usecases/get_trip_expense_ledger_entries_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('GetTripExpenseLedgerEntriesUseCase', () {
    test('uses company and trimmed trip scope', () async {
      final repository = _FakeRepository();
      final result = await GetTripExpenseLedgerEntriesUseCase(repository)(
        GetTripExpenseLedgerEntriesParams(
          currentCompanyContext: _context(CompanyRole.viewer),
          tripId: '  trip-1  ',
          includeVoided: true,
        ),
      );

      expect(result, isA<Success<List<ExpenseLedgerEntry>>>());
      expect(repository.tripCalls, 1);
      expect(repository.companyId, 'company-1');
      expect(repository.tripId, 'trip-1');
      expect(repository.includeVoided, isTrue);
    });

    test('rejects empty trip id before repository execution', () async {
      final repository = _FakeRepository();
      final result = await GetTripExpenseLedgerEntriesUseCase(repository)(
        GetTripExpenseLedgerEntriesParams(
          currentCompanyContext: _context(CompanyRole.owner),
          tripId: '   ',
        ),
      );

      expect(
        result.failureOrNull?.code,
        ExpenseLedgerFailureCodes.validationAttributionInvalid,
      );
      expect(repository.tripCalls, 0);
    });

    test('denies driver read access', () async {
      final repository = _FakeRepository();
      final result = await GetTripExpenseLedgerEntriesUseCase(repository)(
        GetTripExpenseLedgerEntriesParams(
          currentCompanyContext: _context(CompanyRole.driver),
          tripId: 'trip-1',
        ),
      );

      expect(
        result.failureOrNull?.code,
        ExpenseLedgerFailureCodes.permissionView,
      );
      expect(repository.tripCalls, 0);
    });
  });
}

CurrentCompanyContext _context(CompanyRole role) => CurrentCompanyContext(
  company: const Company(id: 'company-1', name: 'Horus'),
  role: role,
);

final class _FakeRepository implements ExpenseLedgerRepository {
  int tripCalls = 0;
  String? companyId;
  String? tripId;
  bool? includeVoided;

  @override
  Future<Result<List<ExpenseLedgerEntry>>> getEntriesForTrip({
    required String companyId,
    required String tripId,
    bool includeVoided = false,
  }) async {
    tripCalls++;
    this.companyId = companyId;
    this.tripId = tripId;
    this.includeVoided = includeVoided;
    return const Success([]);
  }

  @override
  Future<Result<List<ExpenseLedgerEntry>>> getEntries({
    required String companyId,
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
