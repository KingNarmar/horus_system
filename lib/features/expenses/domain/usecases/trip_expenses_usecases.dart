import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/expense_type_option.dart';
import '../entities/trip_expense.dart';
import '../entities/trip_expense_paid_by.dart';
import '../entities/trip_expense_write_data.dart';
import '../policies/trip_expenses_permission_policy.dart';
import '../repositories/trip_expenses_repository.dart';

class GetTripExpensesParams {
  final CurrentCompanyContext currentCompanyContext;
  final String tripId;

  const GetTripExpensesParams({
    required this.currentCompanyContext,
    required this.tripId,
  });
}

class GetExpenseTypesParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetExpenseTypesParams({required this.currentCompanyContext});
}

class AddTripExpenseParams {
  final CurrentCompanyContext currentCompanyContext;
  final String tripId;
  final String? expenseTypeId;
  final String expenseName;
  final double amount;
  final TripExpensePaidBy paidBy;
  final DateTime expenseDate;
  final String? notes;

  const AddTripExpenseParams({
    required this.currentCompanyContext,
    required this.tripId,
    required this.expenseName,
    required this.amount,
    required this.paidBy,
    required this.expenseDate,
    this.expenseTypeId,
    this.notes,
  });
}

class UpdateTripExpenseParams {
  final CurrentCompanyContext currentCompanyContext;
  final String id;
  final String tripId;
  final String? expenseTypeId;
  final String expenseName;
  final double amount;
  final TripExpensePaidBy paidBy;
  final DateTime expenseDate;
  final String? notes;

  const UpdateTripExpenseParams({
    required this.currentCompanyContext,
    required this.id,
    required this.tripId,
    required this.expenseName,
    required this.amount,
    required this.paidBy,
    required this.expenseDate,
    this.expenseTypeId,
    this.notes,
  });
}

class GetTripExpensesUseCase
    implements UseCase<List<TripExpense>, GetTripExpensesParams> {
  final TripExpensesRepository _repository;

  const GetTripExpensesUseCase(this._repository);

  @override
  Future<Result<List<TripExpense>>> call(GetTripExpensesParams params) {
    final context = params.currentCompanyContext;

    if (!TripExpensesPermissionPolicy.canViewTripExpenses(context.role)) {
      return Future.value(
        const FailureResult<List<TripExpense>>(
          PermissionFailure(
            code: FailureCodes.permissionTripExpensesView,
            message: 'Trip expenses access is not allowed.',
          ),
        ),
      );
    }

    final tripId = _optional(params.tripId);
    if (tripId == null) {
      return Future.value(
        const FailureResult<List<TripExpense>>(
          ValidationFailure(
            code: FailureCodes.validationTripIdRequired,
            message: 'Trip id is required.',
          ),
        ),
      );
    }

    return _repository.getTripExpenses(
      companyId: context.companyId,
      tripId: tripId,
    );
  }
}

class GetExpenseTypesUseCase
    implements UseCase<List<ExpenseTypeOption>, GetExpenseTypesParams> {
  final TripExpensesRepository _repository;

  const GetExpenseTypesUseCase(this._repository);

  @override
  Future<Result<List<ExpenseTypeOption>>> call(GetExpenseTypesParams params) {
    final context = params.currentCompanyContext;

    if (!TripExpensesPermissionPolicy.canViewTripExpenses(context.role)) {
      return Future.value(
        const FailureResult<List<ExpenseTypeOption>>(
          PermissionFailure(
            code: FailureCodes.permissionTripExpensesView,
            message: 'Trip expenses access is not allowed.',
          ),
        ),
      );
    }

    return _repository.getExpenseTypes(companyId: context.companyId);
  }
}

class AddTripExpenseUseCase
    implements UseCase<TripExpense, AddTripExpenseParams> {
  final TripExpensesRepository _repository;

  const AddTripExpenseUseCase(this._repository);

  @override
  Future<Result<TripExpense>> call(AddTripExpenseParams params) async {
    final failure = _validateWritableExpense(
      context: params.currentCompanyContext,
      tripId: params.tripId,
      expenseName: params.expenseName,
      amount: params.amount,
    );

    if (failure != null) return FailureResult<TripExpense>(failure);

    final context = params.currentCompanyContext;
    final data = TripExpenseWriteData(
      companyId: context.companyId,
      tripId: params.tripId.trim(),
      expenseTypeId: _optional(params.expenseTypeId),
      expenseName: params.expenseName.trim(),
      amount: params.amount,
      paidBy: params.paidBy,
      expenseDate: params.expenseDate,
      notes: _optional(params.notes),
    );

    return _repository.addTripExpense(data: data, actorRole: context.role.value);
  }
}

class UpdateTripExpenseUseCase
    implements UseCase<TripExpense, UpdateTripExpenseParams> {
  final TripExpensesRepository _repository;

  const UpdateTripExpenseUseCase(this._repository);

  @override
  Future<Result<TripExpense>> call(UpdateTripExpenseParams params) async {
    final id = _optional(params.id);
    if (id == null) {
      return const FailureResult<TripExpense>(
        ValidationFailure(
          code: FailureCodes.validationTripExpenseIdRequired,
          message: 'Trip expense id is required.',
        ),
      );
    }

    final failure = _validateWritableExpense(
      context: params.currentCompanyContext,
      tripId: params.tripId,
      expenseName: params.expenseName,
      amount: params.amount,
    );

    if (failure != null) return FailureResult<TripExpense>(failure);

    final context = params.currentCompanyContext;
    final data = TripExpenseWriteData(
      companyId: context.companyId,
      tripId: params.tripId.trim(),
      expenseTypeId: _optional(params.expenseTypeId),
      expenseName: params.expenseName.trim(),
      amount: params.amount,
      paidBy: params.paidBy,
      expenseDate: params.expenseDate,
      notes: _optional(params.notes),
    );

    return _repository.updateTripExpense(
      id: id,
      data: data,
      actorRole: context.role.value,
    );
  }
}

Failure? _validateWritableExpense({
  required CurrentCompanyContext context,
  required String tripId,
  required String expenseName,
  required double amount,
}) {
  if (!TripExpensesPermissionPolicy.canManageTripExpenses(context.role)) {
    return const PermissionFailure(
      code: FailureCodes.permissionTripExpensesManagement,
      message: 'Trip expenses management is not allowed.',
    );
  }

  if (_optional(tripId) == null) {
    return const ValidationFailure(
      code: FailureCodes.validationTripIdRequired,
      message: 'Trip id is required.',
    );
  }

  if (_optional(expenseName) == null) {
    return const ValidationFailure(
      code: FailureCodes.validationTripExpenseNameRequired,
      message: 'Expense name is required.',
    );
  }

  if (amount <= 0) {
    return const ValidationFailure(
      code: FailureCodes.validationTripExpenseAmountPositive,
      message: 'Expense amount must be greater than zero.',
    );
  }

  return null;
}

String? _optional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
