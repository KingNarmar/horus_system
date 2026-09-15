import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type.dart';
import 'package:horus_system/features/expense_types/domain/repositories/expense_types_repository.dart';
import 'package:horus_system/features/expense_types/domain/usecases/get_active_expense_types_usecase.dart';
import 'package:horus_system/features/expense_types/domain/usecases/get_expense_type_catalog_usecase.dart';
import 'package:horus_system/features/expense_types/domain/usecases/get_ledger_eligible_expense_types_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('Expense type read use cases', () {
    test('catalog lookup trims company id and preserves tenant scope', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await GetExpenseTypeCatalogUseCase(repository)(
        GetExpenseTypeCatalogParams(
          currentCompanyContext: _context(
            CompanyRole.operations,
            companyId: '  company-1  ',
          ),
        ),
      );

      expect(result, isA<Success<List<ExpenseType>>>());
      expect(repository.lastCatalogCompanyId, 'company-1');
    });

    test('catalog lookup rejects driver before repository access', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await GetExpenseTypeCatalogUseCase(repository)(
        GetExpenseTypeCatalogParams(
          currentCompanyContext: _context(CompanyRole.driver),
        ),
      );

      expect(result, isA<FailureResult<List<ExpenseType>>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionExpenseTypesView,
      );
      expect(repository.lastCatalogCompanyId, isNull);
    });

    test('catalog lookup validates company id before repository access', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await GetExpenseTypeCatalogUseCase(repository)(
        GetExpenseTypeCatalogParams(
          currentCompanyContext: _context(
            CompanyRole.owner,
            companyId: '   ',
          ),
        ),
      );

      expect(result, isA<FailureResult<List<ExpenseType>>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationCompanyIdRequired,
      );
      expect(repository.lastCatalogCompanyId, isNull);
    });

    test('active lookup keeps company scope', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await GetActiveExpenseTypesUseCase(repository)(
        GetActiveExpenseTypesParams(
          currentCompanyContext: _context(
            CompanyRole.viewer,
            companyId: ' company-2 ',
          ),
        ),
      );

      expect(result, isA<Success<List<ExpenseType>>>());
      expect(repository.lastActiveCompanyId, 'company-2');
    });

    test('ledger eligible lookup uses the selected company scope', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await GetLedgerEligibleExpenseTypesUseCase(repository)(
        GetLedgerEligibleExpenseTypesParams(
          currentCompanyContext: _context(
            CompanyRole.accountant,
            companyId: 'company-3',
          ),
        ),
      );

      expect(result, isA<Success<List<ExpenseType>>>());
      expect(repository.lastLedgerEligibleCompanyId, 'company-3');
    });
  });
}

CurrentCompanyContext _context(
  CompanyRole role, {
  String companyId = 'company-1',
}) {
  return CurrentCompanyContext(
    company: Company(id: companyId, name: 'Horus Transport'),
    role: role,
  );
}

const _expenseType = ExpenseType(
  id: 'expense-1',
  companyId: 'company-1',
  name: 'Fuel',
  code: 'fuel',
  isActive: true,
  isLedgerEligible: true,
);

class _FakeExpenseTypesRepository implements ExpenseTypesRepository {
  String? lastCatalogCompanyId;
  String? lastActiveCompanyId;
  String? lastLedgerEligibleCompanyId;

  @override
  Future<Result<List<ExpenseType>>> getExpenseTypes({
    required String companyId,
  }) async {
    lastCatalogCompanyId = companyId;
    return const Success<List<ExpenseType>>([_expenseType]);
  }

  @override
  Future<Result<List<ExpenseType>>> getActiveExpenseTypes({
    required String companyId,
  }) async {
    lastActiveCompanyId = companyId;
    return const Success<List<ExpenseType>>([_expenseType]);
  }

  @override
  Future<Result<List<ExpenseType>>> getLedgerEligibleExpenseTypes({
    required String companyId,
  }) async {
    lastLedgerEligibleCompanyId = companyId;
    return const Success<List<ExpenseType>>([_expenseType]);
  }
}
