import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type_write_data.dart';
import 'package:horus_system/features/expense_types/domain/repositories/expense_types_repository.dart';
import 'package:horus_system/features/expense_types/domain/usecases/add_expense_type_usecase.dart';
import 'package:horus_system/features/expense_types/domain/usecases/deactivate_expense_type_usecase.dart';
import 'package:horus_system/features/expense_types/domain/usecases/get_active_expense_types_usecase.dart';
import 'package:horus_system/features/expense_types/domain/usecases/get_expense_types_usecase.dart';
import 'package:horus_system/features/expense_types/domain/usecases/reactivate_expense_type_usecase.dart';
import 'package:horus_system/features/expense_types/domain/usecases/update_expense_type_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('Expense type read use cases', () {
    test('settings lookup trims company id for a management role', () async {
      final repository = _FakeExpenseTypesRepository();
      final useCase = GetExpenseTypesUseCase(repository);

      final result = await useCase(
        GetExpenseTypesParams(
          currentCompanyContext: _context(
            CompanyRole.accountant,
            companyId: '  company-1  ',
          ),
        ),
      );

      expect(result, isA<Success<List<ExpenseType>>>());
      expect(repository.lastGetCompanyId, 'company-1');
    });

    test('settings lookup rejects operations role before repository', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await GetExpenseTypesUseCase(repository)(
        GetExpenseTypesParams(
          currentCompanyContext: _context(CompanyRole.operations),
        ),
      );

      expect(result, isA<FailureResult<List<ExpenseType>>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionExpenseTypesManagement,
      );
      expect(repository.lastGetCompanyId, isNull);
    });

    test('settings lookup validates company id before repository', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await GetExpenseTypesUseCase(repository)(
        GetExpenseTypesParams(
          currentCompanyContext: _context(CompanyRole.owner, companyId: '   '),
        ),
      );

      expect(result, isA<FailureResult<List<ExpenseType>>>());
      expect(result.failureOrNull?.code, FailureCodes.validationCompanyIdRequired);
      expect(repository.lastGetCompanyId, isNull);
    });

    test('active lookup allows operations and preserves tenant scope', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await GetActiveExpenseTypesUseCase(repository)(
        GetActiveExpenseTypesParams(
          currentCompanyContext: _context(
            CompanyRole.operations,
            companyId: ' company-2 ',
          ),
        ),
      );

      expect(result, isA<Success<List<ExpenseType>>>());
      expect(repository.lastActiveCompanyId, 'company-2');
    });

    test('active lookup rejects driver role before repository', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await GetActiveExpenseTypesUseCase(repository)(
        GetActiveExpenseTypesParams(
          currentCompanyContext: _context(CompanyRole.driver),
        ),
      );

      expect(result, isA<FailureResult<List<ExpenseType>>>());
      expect(result.failureOrNull?.code, FailureCodes.permissionExpenseTypesView);
      expect(repository.lastActiveCompanyId, isNull);
    });
  });

  group('Expense type mutation use cases', () {
    test('add trims name and forwards tenant plus actor role', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await AddExpenseTypeUseCase(repository)(
        AddExpenseTypeParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          name: '  Fuel surcharge  ',
        ),
      );

      expect(result, isA<Success<ExpenseType>>());
      expect(repository.lastWriteData?.companyId, 'company-1');
      expect(repository.lastWriteData?.name, 'Fuel surcharge');
      expect(repository.lastActorRole, 'accountant');
    });

    test('add rejects blank name without repository mutation', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await AddExpenseTypeUseCase(repository)(
        AddExpenseTypeParams(
          currentCompanyContext: _context(CompanyRole.admin),
          name: '   ',
        ),
      );

      expect(result, isA<FailureResult<ExpenseType>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationExpenseTypeNameRequired,
      );
      expect(repository.lastWriteData, isNull);
    });

    test('add rejects non-management role before validation or mutation', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await AddExpenseTypeUseCase(repository)(
        AddExpenseTypeParams(
          currentCompanyContext: _context(CompanyRole.viewer),
          name: 'Fuel',
        ),
      );

      expect(result, isA<FailureResult<ExpenseType>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionExpenseTypesManagement,
      );
      expect(repository.lastWriteData, isNull);
    });

    test('update trims id and name before repository mutation', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await UpdateExpenseTypeUseCase(repository)(
        UpdateExpenseTypeParams(
          currentCompanyContext: _context(CompanyRole.owner),
          expenseTypeId: '  expense-1  ',
          name: '  Toll fees  ',
        ),
      );

      expect(result, isA<Success<ExpenseType>>());
      expect(repository.lastExpenseTypeId, 'expense-1');
      expect(repository.lastWriteData?.name, 'Toll fees');
      expect(repository.lastActorRole, 'owner');
    });

    test('update rejects blank id without repository mutation', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await UpdateExpenseTypeUseCase(repository)(
        UpdateExpenseTypeParams(
          currentCompanyContext: _context(CompanyRole.admin),
          expenseTypeId: ' ',
          name: 'Fuel',
        ),
      );

      expect(result, isA<FailureResult<ExpenseType>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationExpenseTypeIdRequired,
      );
      expect(repository.lastExpenseTypeId, isNull);
    });

    test('deactivate trims id and forwards company plus actor role', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await DeactivateExpenseTypeUseCase(repository)(
        DeactivateExpenseTypeParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          expenseTypeId: '  expense-1 ',
        ),
      );

      expect(result, isA<Success<ExpenseType>>());
      expect(repository.lastStatusCompanyId, 'company-1');
      expect(repository.lastExpenseTypeId, 'expense-1');
      expect(repository.lastActorRole, 'accountant');
      expect(repository.lastStatusActive, isFalse);
    });

    test('reactivate trims id and forwards company plus actor role', () async {
      final repository = _FakeExpenseTypesRepository();
      final result = await ReactivateExpenseTypeUseCase(repository)(
        ReactivateExpenseTypeParams(
          currentCompanyContext: _context(CompanyRole.admin),
          expenseTypeId: ' expense-1  ',
        ),
      );

      expect(result, isA<Success<ExpenseType>>());
      expect(repository.lastStatusCompanyId, 'company-1');
      expect(repository.lastExpenseTypeId, 'expense-1');
      expect(repository.lastActorRole, 'admin');
      expect(repository.lastStatusActive, isTrue);
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
  isActive: true,
);

class _FakeExpenseTypesRepository implements ExpenseTypesRepository {
  String? lastGetCompanyId;
  String? lastActiveCompanyId;
  String? lastStatusCompanyId;
  String? lastExpenseTypeId;
  String? lastActorRole;
  bool? lastStatusActive;
  ExpenseTypeWriteData? lastWriteData;

  @override
  Future<Result<List<ExpenseType>>> getExpenseTypes({
    required String companyId,
  }) async {
    lastGetCompanyId = companyId;
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
  Future<Result<ExpenseType>> addExpenseType({
    required ExpenseTypeWriteData data,
    required String actorRole,
  }) async {
    lastWriteData = data;
    lastActorRole = actorRole;
    return Success<ExpenseType>(
      ExpenseType(
        id: _expenseType.id,
        companyId: data.companyId,
        name: data.name,
        isActive: true,
      ),
    );
  }

  @override
  Future<Result<ExpenseType>> updateExpenseType({
    required String expenseTypeId,
    required ExpenseTypeWriteData data,
    required String actorRole,
  }) async {
    lastExpenseTypeId = expenseTypeId;
    lastWriteData = data;
    lastActorRole = actorRole;
    return Success<ExpenseType>(
      ExpenseType(
        id: expenseTypeId,
        companyId: data.companyId,
        name: data.name,
        isActive: true,
      ),
    );
  }

  @override
  Future<Result<ExpenseType>> deactivateExpenseType({
    required String companyId,
    required String expenseTypeId,
    required String actorRole,
  }) async {
    lastStatusCompanyId = companyId;
    lastExpenseTypeId = expenseTypeId;
    lastActorRole = actorRole;
    lastStatusActive = false;
    return Success<ExpenseType>(
      ExpenseType(
        id: expenseTypeId,
        companyId: companyId,
        name: _expenseType.name,
        isActive: false,
      ),
    );
  }

  @override
  Future<Result<ExpenseType>> reactivateExpenseType({
    required String companyId,
    required String expenseTypeId,
    required String actorRole,
  }) async {
    lastStatusCompanyId = companyId;
    lastExpenseTypeId = expenseTypeId;
    lastActorRole = actorRole;
    lastStatusActive = true;
    return Success<ExpenseType>(
      ExpenseType(
        id: expenseTypeId,
        companyId: companyId,
        name: _expenseType.name,
        isActive: true,
      ),
    );
  }
}
