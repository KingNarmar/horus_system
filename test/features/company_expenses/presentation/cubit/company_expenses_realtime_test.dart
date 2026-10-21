import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/services/business_time_zone_converter.dart';
import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import 'package:horus_system/core/usecases/get_company_business_date_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense_category.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense_form_lookups.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense_void_data.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense_write_data.dart';
import 'package:horus_system/features/company_expenses/domain/repositories/company_expenses_repository.dart';
import 'package:horus_system/features/company_expenses/domain/usecases/can_manage_company_expenses_usecase.dart';
import 'package:horus_system/features/company_expenses/domain/usecases/company_expenses_usecases.dart';
import 'package:horus_system/features/company_expenses/presentation/cubit/company_expenses_cubit.dart';
import 'package:horus_system/features/company_expenses/presentation/cubit/company_expenses_state.dart';

const _companyA = CurrentCompanyContext(
  company: Company(id: 'company-a', name: 'Company A'),
  role: CompanyRole.accountant,
);
const _companyB = CurrentCompanyContext(
  company: Company(id: 'company-b', name: 'Company B'),
  role: CompanyRole.accountant,
);
final _businessDate = BusinessDate(year: 2026, month: 10, day: 21);

CompanyExpense _expense(
  String id, {
  String companyId = 'company-a',
  bool voided = false,
  double amount = 30,
  DateTime? updatedAt,
}) => CompanyExpense(
  id: id,
  companyId: companyId,
  categoryId: 'category-a',
  amount: amount,
  expenseDate: _businessDate,
  isVoided: voided,
  updatedAt: updatedAt,
);

CompanyExpensesCubit _cubit(_ExpenseRepository repository) =>
    CompanyExpensesCubit(
      getBusinessDateUseCase: GetCompanyBusinessDateUseCase(_DateProvider()),
      canManageCompanyExpensesUseCase: const CanManageCompanyExpensesUseCase(),
      getCategoriesUseCase: GetCompanyExpenseCategoriesUseCase(repository),
      getExpensesUseCase: GetCompanyExpensesUseCase(repository),
      getFormLookupsUseCase: GetCompanyExpenseFormLookupsUseCase(repository),
      addExpenseUseCase: AddCompanyExpenseUseCase(repository),
      updateExpenseUseCase: UpdateCompanyExpenseUseCase(repository),
      voidExpenseUseCase: VoidCompanyExpenseUseCase(repository),
      getEntityAuditLogsUseCase: GetEntityAuditLogsUseCase(_AuditRepository()),
      convertInstantsToBusinessLocalDateTimesUseCase:
          ConvertInstantsToBusinessLocalDateTimesUseCase(_UnusedConverter()),
    );

void main() {
  test(
    'incoming company expense change silently refreshes and preserves search',
    () async {
      final repo = _ExpenseRepository()..rows['company-a'] = [_expense('one')];
      final cubit = _cubit(repo);
      addTearDown(cubit.close);
      await cubit.loadCompanyExpenses(_companyA);
      cubit.setSearchQuery('reference');

      repo.rows['company-a'] = [_expense('one'), _expense('two')];
      await cubit.refreshCompanyExpensesFromRealtime();

      final state = cubit.state as CompanyExpensesLoaded;
      expect(state.searchQuery, 'reference');
      expect(state.allExpenses.map((expense) => expense.id), ['one', 'two']);
      expect(state.realtimeRefreshFailure, isNull);
      expect(repo.reads, 2);
    },
  );

  test(
    'remote void updates open details without reintroducing hidden row',
    () async {
      final repo = _ExpenseRepository()..rows['company-a'] = [_expense('one')];
      final cubit = _cubit(repo);
      addTearDown(cubit.close);
      await cubit.loadCompanyExpenses(_companyA);
      await cubit.loadExpenseActivity(_expense('one'));

      repo.rows['company-a'] = [
        _expense('one', voided: true, updatedAt: DateTime.utc(2026, 10, 21)),
      ];
      await cubit.refreshCompanyExpensesFromRealtime();
      await Future<void>.delayed(Duration.zero);

      final state = cubit.state as CompanyExpensesLoaded;
      expect(state.allExpenses, isEmpty);
      expect(state.selectedExpense?.isVoided, isTrue);
      expect(repo.includeVoidedRequests.last, isTrue);
    },
  );

  test(
    'bursty hints coalesce while an authoritative read is pending',
    () async {
      final repo = _ExpenseRepository()..rows['company-a'] = [_expense('one')];
      final cubit = _cubit(repo);
      addTearDown(cubit.close);
      await cubit.loadCompanyExpenses(_companyA);
      final delayed = Completer<Result<List<CompanyExpense>>>();
      repo.delayedRead = delayed;

      final first = cubit.refreshCompanyExpensesFromRealtime();
      await Future<void>.delayed(Duration.zero);
      final second = cubit.refreshCompanyExpensesFromRealtime();
      repo.rows['company-a'] = [_expense('one'), _expense('three')];
      delayed.complete(Success([_expense('one')]));
      await Future.wait([first, second]);

      expect(repo.reads, 3);
      expect((cubit.state as CompanyExpensesLoaded).allExpenses.length, 2);
    },
  );

  test(
    'late old-tenant responses cannot replace new-company records',
    () async {
      final repo = _ExpenseRepository()..rows['company-a'] = [_expense('one')];
      final cubit = _cubit(repo);
      addTearDown(cubit.close);
      await cubit.loadCompanyExpenses(_companyA);
      final delayed = Completer<Result<List<CompanyExpense>>>();
      repo.delayedRead = delayed;
      final prior = cubit.refreshCompanyExpensesFromRealtime();
      await Future<void>.delayed(Duration.zero);

      repo.rows['company-b'] = [_expense('two', companyId: 'company-b')];
      await cubit.loadCompanyExpenses(_companyB);
      delayed.complete(Success([_expense('foreign-old')]));
      await prior;

      final state = cubit.state as CompanyExpensesLoaded;
      expect(state.currentCompanyContext.companyId, 'company-b');
      expect(state.allExpenses.single.id, 'two');
    },
  );

  test('server authorization denial clears stale company financials', () async {
    final repo = _ExpenseRepository()..rows['company-a'] = [_expense('one')];
    final cubit = _cubit(repo);
    addTearDown(cubit.close);
    await cubit.loadCompanyExpenses(_companyA);
    repo.nextResult = const FailureResult<List<CompanyExpense>>(
      PermissionFailure(code: FailureCodes.permissionCompanyExpensesView),
    );
    await cubit.refreshCompanyExpensesFromRealtime();
    expect(cubit.state, isA<CompanyExpensesFailure>());
  });

  test(
    'reconnect preserves filters while updating the list and lookups',
    () async {
      final repo = _ExpenseRepository()..rows['company-a'] = [_expense('one')];
      final cubit = _cubit(repo);
      addTearDown(cubit.close);
      await cubit.loadCompanyExpenses(_companyA);
      cubit.setSearchQuery('test');
      repo.rows['company-a'] = [_expense('one'), _expense('two')];
      await cubit.reconcileCompanyExpensesAfterReconnect(_companyA);

      final state = cubit.state as CompanyExpensesLoaded;
      expect(state.searchQuery, 'test');
      expect(state.allExpenses.length, 2);
      expect(repo.categoriesReads, 2);
    },
  );
}

final class _DateProvider implements CompanyBusinessDateProvider {
  @override
  Future<Result<BusinessDate>> getBusinessDate({
    required String companyId,
  }) async => Success(_businessDate);
}

final class _UnusedConverter implements BusinessTimeZoneConverter {
  @override
  Result<BusinessLocalDateTime> toBusinessLocalDateTime({
    required DateTime instant,
    required String timeZoneId,
  }) => throw UnimplementedError();

  @override
  Result<DateTime> toUtcInstant({
    required BusinessLocalDateTime localDateTime,
    required String timeZoneId,
  }) => throw UnimplementedError();
}

final class _AuditRepository implements AuditLogRepository {
  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async => const Success(<AuditLog>[]);
}

final class _ExpenseRepository implements CompanyExpensesRepository {
  final Map<String, List<CompanyExpense>> rows = {};
  final List<bool> includeVoidedRequests = [];
  int reads = 0;
  int categoriesReads = 0;
  Completer<Result<List<CompanyExpense>>>? delayedRead;
  Result<List<CompanyExpense>>? nextResult;

  @override
  Future<Result<List<CompanyExpense>>> getCompanyExpenses({
    required String companyId,
    bool includeVoided = false,
  }) async {
    reads++;
    includeVoidedRequests.add(includeVoided);
    final deferred = delayedRead;
    if (deferred != null) {
      delayedRead = null;
      return deferred.future;
    }
    final result = nextResult;
    if (result != null) {
      nextResult = null;
      return result;
    }
    final current = rows[companyId] ?? const <CompanyExpense>[];
    return Success(
      includeVoided
          ? current
          : current.where((expense) => !expense.isVoided).toList(),
    );
  }

  @override
  Future<Result<List<CompanyExpenseCategory>>> getCategories({
    required String companyId,
    bool includeInactive = false,
  }) async {
    categoriesReads++;
    return const Success(<CompanyExpenseCategory>[]);
  }

  @override
  Future<Result<CompanyExpenseFormLookups>> getFormLookups({
    required String companyId,
  }) async => const Success(CompanyExpenseFormLookups());

  @override
  Future<Result<CompanyExpense>> addCompanyExpense({
    required CompanyExpenseWriteData data,
    required String actorRole,
  }) async => Success(
    _expense('added', companyId: data.companyId, amount: data.amount),
  );

  @override
  Future<Result<CompanyExpense>> updateCompanyExpense({
    required String id,
    required CompanyExpenseWriteData data,
    required String actorRole,
  }) async =>
      Success(_expense(id, companyId: data.companyId, amount: data.amount));

  @override
  Future<Result<CompanyExpense>> voidCompanyExpense({
    required CompanyExpenseVoidData data,
    required String actorRole,
  }) async => Success(
    _expense(data.expenseId, companyId: data.companyId, voided: true),
  );
}
