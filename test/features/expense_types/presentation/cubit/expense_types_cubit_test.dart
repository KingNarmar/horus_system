import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type_status_filter.dart';
import 'package:horus_system/features/expense_types/domain/usecases/get_expense_type_catalog_usecase.dart';
import 'package:horus_system/features/expense_types/presentation/cubit/expense_types_cubit.dart';
import 'package:horus_system/features/expense_types/presentation/cubit/expense_types_state.dart';
import 'package:test/test.dart';

import '../../helpers/fake_expense_types_repository.dart';

void main() {
  test('load sorts the catalog and status filtering stays local', () async {
    final repository = FakeExpenseTypesRepository()
      ..types = const [
        ExpenseType(
          id: 'road-fees',
          companyId: 'company-1',
          name: 'Road fees',
          code: 'road_fees',
          isActive: false,
        ),
        ExpenseType(
          id: 'fuel',
          companyId: 'company-1',
          name: 'Fuel',
          code: 'fuel',
          isActive: true,
        ),
      ];
    final cubit = _cubit(repository);

    await cubit.loadExpenseTypes(_context());
    var loaded = cubit.state as ExpenseTypesLoaded;
    expect(loaded.allTypes.map((item) => item.id), ['fuel', 'road-fees']);
    expect(loaded.visibleTypes.map((item) => item.id), ['fuel']);

    cubit.setStatusFilter(ExpenseTypeStatusFilter.inactive);
    loaded = cubit.state as ExpenseTypesLoaded;
    expect(loaded.visibleTypes.map((item) => item.id), ['road-fees']);

    await cubit.close();
  });

  test('reload preserves the selected status filter', () async {
    final repository = FakeExpenseTypesRepository()
      ..types = const [
        ExpenseType(
          id: 'fuel',
          companyId: 'company-1',
          name: 'Fuel',
          isActive: true,
        ),
      ];
    final cubit = _cubit(repository);

    await cubit.loadExpenseTypes(_context());
    cubit.setStatusFilter(ExpenseTypeStatusFilter.all);
    await cubit.loadExpenseTypes(_context());

    expect(
      (cubit.state as ExpenseTypesLoaded).statusFilter,
      ExpenseTypeStatusFilter.all,
    );
    await cubit.close();
  });

  test('read failure is exposed as a typed failure state', () async {
    final repository = FakeExpenseTypesRepository()
      ..nextFailure = const UnexpectedFailure(
        code: FailureCodes.unexpectedError,
      );
    final cubit = _cubit(repository);

    await cubit.loadExpenseTypes(_context());

    final failure = cubit.state as ExpenseTypesFailure;
    expect(failure.failure.code, FailureCodes.unexpectedError);
    await cubit.close();
  });
}

ExpenseTypesCubit _cubit(FakeExpenseTypesRepository repository) {
  return ExpenseTypesCubit(
    getExpenseTypeCatalogUseCase: GetExpenseTypeCatalogUseCase(repository),
  );
}

CurrentCompanyContext _context() {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Company One'),
    role: CompanyRole.accountant,
  );
}
