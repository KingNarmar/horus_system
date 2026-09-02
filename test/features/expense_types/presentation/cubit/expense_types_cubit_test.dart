import 'dart:async';

import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type_status_filter.dart';
import 'package:horus_system/features/expense_types/domain/usecases/add_expense_type_usecase.dart';
import 'package:horus_system/features/expense_types/domain/usecases/deactivate_expense_type_usecase.dart';
import 'package:horus_system/features/expense_types/domain/usecases/get_expense_types_usecase.dart';
import 'package:horus_system/features/expense_types/domain/usecases/reactivate_expense_type_usecase.dart';
import 'package:horus_system/features/expense_types/domain/usecases/update_expense_type_usecase.dart';
import 'package:horus_system/features/expense_types/presentation/cubit/expense_types_cubit.dart';
import 'package:horus_system/features/expense_types/presentation/cubit/expense_types_state.dart';
import 'package:test/test.dart';

import '../../helpers/fake_expense_types_repository.dart';

void main() {
  test('load sorts types and filter stays local to the cubit', () async {
    final repository = FakeExpenseTypesRepository()
      ..types = const [
        ExpenseType(
          id: 'road-fees',
          companyId: 'company-1',
          name: 'Road fees',
          isActive: false,
        ),
        ExpenseType(
          id: 'fuel',
          companyId: 'company-1',
          name: 'Fuel',
          isActive: true,
        ),
      ];
    final cubit = _cubit(repository);

    await cubit.loadExpenseTypes(_context());
    var loaded = cubit.state as ExpenseTypesLoaded;
    expect(loaded.allTypes.map((item) => item.id), ['fuel', 'road-fees']);
    expect(loaded.visibleTypes.map((item) => item.id), ['fuel']);
    expect(loaded.canManageExpenseTypes, isTrue);

    cubit.setStatusFilter(ExpenseTypeStatusFilter.inactive);
    loaded = cubit.state as ExpenseTypesLoaded;
    expect(loaded.visibleTypes.map((item) => item.id), ['road-fees']);

    await cubit.close();
  });

  test('successful add upserts locally and emits mutation feedback', () async {
    final repository = FakeExpenseTypesRepository();
    final cubit = _cubit(repository);
    await cubit.loadExpenseTypes(_context());

    final succeeded = await cubit.addExpenseType('Fuel surcharge');
    final loaded = cubit.state as ExpenseTypesLoaded;

    expect(succeeded, isTrue);
    expect(loaded.allTypes.single.name, 'Fuel surcharge');
    expect(loaded.completedMutation, ExpenseTypeMutation.created);
    expect(loaded.feedbackSequence, 1);
    expect(loaded.isSubmitting, isFalse);
    await cubit.close();
  });

  test('successful update replaces the matching type locally', () async {
    const fuel = ExpenseType(
      id: 'fuel',
      companyId: 'company-1',
      name: 'Fuel',
      isActive: true,
    );
    final repository = FakeExpenseTypesRepository()..types = const [fuel];
    final cubit = _cubit(repository);
    await cubit.loadExpenseTypes(_context());

    final succeeded = await cubit.updateExpenseType(
      expenseType: fuel,
      name: 'Diesel',
    );
    final loaded = cubit.state as ExpenseTypesLoaded;

    expect(succeeded, isTrue);
    expect(loaded.allTypes.single.name, 'Diesel');
    expect(loaded.completedMutation, ExpenseTypeMutation.updated);
    expect(loaded.feedbackSequence, 1);
    await cubit.close();
  });

  test(
    'mutation failure preserves loaded data and exposes typed failure',
    () async {
      const fuel = ExpenseType(
        id: 'fuel',
        companyId: 'company-1',
        name: 'Fuel',
        isActive: true,
      );
      final repository = FakeExpenseTypesRepository()..types = const [fuel];
      final cubit = _cubit(repository);
      await cubit.loadExpenseTypes(_context());
      repository.nextFailure = const ConflictFailure(
        code: FailureCodes.conflictExpenseTypeDuplicateName,
      );

      final succeeded = await cubit.addExpenseType('fuel');
      final loaded = cubit.state as ExpenseTypesLoaded;

      expect(succeeded, isFalse);
      expect(loaded.allTypes.single.id, 'fuel');
      expect(
        loaded.mutationFailure?.code,
        FailureCodes.conflictExpenseTypeDuplicateName,
      );
      expect(loaded.isSubmitting, isFalse);
      expect(loaded.feedbackSequence, 1);
      await cubit.close();
    },
  );

  test('successful deactivate updates status and clears pending id', () async {
    const fuel = ExpenseType(
      id: 'fuel',
      companyId: 'company-1',
      name: 'Fuel',
      isActive: true,
    );
    final repository = FakeExpenseTypesRepository()..types = const [fuel];
    final cubit = _cubit(repository);
    await cubit.loadExpenseTypes(_context());

    final succeeded = await cubit.deactivateExpenseType(fuel);
    final loaded = cubit.state as ExpenseTypesLoaded;

    expect(succeeded, isTrue);
    expect(loaded.allTypes.single.isActive, isFalse);
    expect(loaded.pendingActionExpenseTypeId, isNull);
    expect(loaded.completedMutation, ExpenseTypeMutation.deactivated);
    await cubit.close();
  });

  test('submit mutation blocks status mutation until it completes', () async {
    const fuel = ExpenseType(
      id: 'fuel',
      companyId: 'company-1',
      name: 'Fuel',
      isActive: true,
    );
    final completer = Completer<Result<ExpenseType>>();
    final repository = FakeExpenseTypesRepository()
      ..types = const [fuel]
      ..mutationCompleter = completer;
    final cubit = _cubit(repository);
    await cubit.loadExpenseTypes(_context());

    final addFuture = cubit.addExpenseType('Road fees');
    final pending = cubit.state as ExpenseTypesLoaded;
    expect(pending.isSubmitting, isTrue);
    expect(pending.isMutationPending, isTrue);

    final statusSucceeded = await cubit.deactivateExpenseType(fuel);
    expect(statusSucceeded, isFalse);

    completer.complete(
      const Success(
        ExpenseType(
          id: 'road-fees',
          companyId: 'company-1',
          name: 'Road fees',
          isActive: true,
        ),
      ),
    );
    expect(await addFuture, isTrue);
    expect((cubit.state as ExpenseTypesLoaded).isMutationPending, isFalse);
    await cubit.close();
  });

  test('status mutation blocks submit mutation until it completes', () async {
    const fuel = ExpenseType(
      id: 'fuel',
      companyId: 'company-1',
      name: 'Fuel',
      isActive: true,
    );
    final completer = Completer<Result<ExpenseType>>();
    final repository = FakeExpenseTypesRepository()
      ..types = const [fuel]
      ..mutationCompleter = completer;
    final cubit = _cubit(repository);
    await cubit.loadExpenseTypes(_context());

    final deactivateFuture = cubit.deactivateExpenseType(fuel);
    final pending = cubit.state as ExpenseTypesLoaded;
    expect(pending.pendingActionExpenseTypeId, 'fuel');
    expect(pending.isMutationPending, isTrue);

    final addSucceeded = await cubit.addExpenseType('Road fees');
    expect(addSucceeded, isFalse);

    completer.complete(
      const Success(
        ExpenseType(
          id: 'fuel',
          companyId: 'company-1',
          name: 'Fuel',
          isActive: false,
        ),
      ),
    );
    expect(await deactivateFuture, isTrue);
    expect((cubit.state as ExpenseTypesLoaded).isMutationPending, isFalse);
    await cubit.close();
  });
}

ExpenseTypesCubit _cubit(FakeExpenseTypesRepository repository) {
  return ExpenseTypesCubit(
    getExpenseTypesUseCase: GetExpenseTypesUseCase(repository),
    addExpenseTypeUseCase: AddExpenseTypeUseCase(repository),
    updateExpenseTypeUseCase: UpdateExpenseTypeUseCase(repository),
    deactivateExpenseTypeUseCase: DeactivateExpenseTypeUseCase(repository),
    reactivateExpenseTypeUseCase: ReactivateExpenseTypeUseCase(repository),
  );
}

CurrentCompanyContext _context() {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Company One'),
    role: CompanyRole.accountant,
  );
}
