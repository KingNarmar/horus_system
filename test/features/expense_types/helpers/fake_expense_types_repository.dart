import 'dart:async';

import 'package:horus_system/core/errors/failure.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type_write_data.dart';
import 'package:horus_system/features/expense_types/domain/repositories/expense_types_repository.dart';

final class FakeExpenseTypesRepository implements ExpenseTypesRepository {
  List<ExpenseType> types = const [];
  List<ExpenseType> activeTypes = const [];
  Failure? nextFailure;
  Completer<Result<ExpenseType>>? mutationCompleter;
  ExpenseTypeWriteData? lastWriteData;
  String? lastActorRole;
  String? lastExpenseTypeId;
  String? lastCompanyId;
  int getAllCalls = 0;
  int getActiveCalls = 0;

  @override
  Future<Result<List<ExpenseType>>> getExpenseTypes({
    required String companyId,
  }) async {
    getAllCalls += 1;
    lastCompanyId = companyId;
    final failure = nextFailure;
    if (failure != null) return FailureResult(failure);
    return Success(types);
  }

  @override
  Future<Result<List<ExpenseType>>> getActiveExpenseTypes({
    required String companyId,
  }) async {
    getActiveCalls += 1;
    lastCompanyId = companyId;
    final failure = nextFailure;
    if (failure != null) return FailureResult(failure);
    return Success(activeTypes);
  }

  @override
  Future<Result<ExpenseType>> addExpenseType({
    required ExpenseTypeWriteData data,
    required String actorRole,
  }) async {
    lastWriteData = data;
    lastActorRole = actorRole;
    final failure = nextFailure;
    if (failure != null) return FailureResult(failure);

    final pendingMutation = mutationCompleter;
    if (pendingMutation != null) return pendingMutation.future;

    return Success(
      ExpenseType(
        id: 'expense-type-new',
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
    final failure = nextFailure;
    if (failure != null) return FailureResult(failure);

    final pendingMutation = mutationCompleter;
    if (pendingMutation != null) return pendingMutation.future;

    return Success(
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
  }) {
    return _changeStatus(
      companyId: companyId,
      expenseTypeId: expenseTypeId,
      actorRole: actorRole,
      isActive: false,
    );
  }

  @override
  Future<Result<ExpenseType>> reactivateExpenseType({
    required String companyId,
    required String expenseTypeId,
    required String actorRole,
  }) {
    return _changeStatus(
      companyId: companyId,
      expenseTypeId: expenseTypeId,
      actorRole: actorRole,
      isActive: true,
    );
  }

  Future<Result<ExpenseType>> _changeStatus({
    required String companyId,
    required String expenseTypeId,
    required String actorRole,
    required bool isActive,
  }) async {
    lastCompanyId = companyId;
    lastExpenseTypeId = expenseTypeId;
    lastActorRole = actorRole;
    final failure = nextFailure;
    if (failure != null) return FailureResult(failure);

    final pendingMutation = mutationCompleter;
    if (pendingMutation != null) return pendingMutation.future;

    var name = 'Expense type';
    for (final type in types) {
      if (type.id == expenseTypeId) {
        name = type.name;
        break;
      }
    }
    return Success(
      ExpenseType(
        id: expenseTypeId,
        companyId: companyId,
        name: name,
        isActive: isActive,
      ),
    );
  }
}
