import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/company_expense.dart';
import '../entities/company_expense_category.dart';
import '../entities/company_expense_void_data.dart';
import '../entities/company_expense_write_data.dart';
import '../policies/company_expenses_permission_policy.dart';
import '../repositories/company_expenses_repository.dart';

class GetCompanyExpenseCategoriesParams {
  final CurrentCompanyContext currentCompanyContext;
  final bool includeInactive;

  const GetCompanyExpenseCategoriesParams({
    required this.currentCompanyContext,
    this.includeInactive = false,
  });
}

class GetCompanyExpensesParams {
  final CurrentCompanyContext currentCompanyContext;
  final bool includeVoided;

  const GetCompanyExpensesParams({
    required this.currentCompanyContext,
    this.includeVoided = false,
  });
}

class AddCompanyExpenseParams {
  final CurrentCompanyContext currentCompanyContext;
  final String categoryId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final String? tripId;
  final double amount;
  final DateTime expenseDate;
  final String? referenceNumber;
  final String? notes;

  const AddCompanyExpenseParams({
    required this.currentCompanyContext,
    required this.categoryId,
    required this.amount,
    required this.expenseDate,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.tripId,
    this.referenceNumber,
    this.notes,
  });
}

class UpdateCompanyExpenseParams {
  final CurrentCompanyContext currentCompanyContext;
  final String expenseId;
  final String categoryId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final String? tripId;
  final double amount;
  final DateTime expenseDate;
  final String? referenceNumber;
  final String? notes;

  const UpdateCompanyExpenseParams({
    required this.currentCompanyContext,
    required this.expenseId,
    required this.categoryId,
    required this.amount,
    required this.expenseDate,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.tripId,
    this.referenceNumber,
    this.notes,
  });
}

class VoidCompanyExpenseParams {
  final CurrentCompanyContext currentCompanyContext;
  final String expenseId;
  final String? reason;

  const VoidCompanyExpenseParams({
    required this.currentCompanyContext,
    required this.expenseId,
    this.reason,
  });
}

class GetCompanyExpenseCategoriesUseCase
    implements
        UseCase<
          List<CompanyExpenseCategory>,
          GetCompanyExpenseCategoriesParams
        > {
  final CompanyExpensesRepository _repository;

  const GetCompanyExpenseCategoriesUseCase(this._repository);

  @override
  Future<Result<List<CompanyExpenseCategory>>> call(
    GetCompanyExpenseCategoriesParams params,
  ) {
    final context = params.currentCompanyContext;
    if (!CompanyExpensesPermissionPolicy.canViewCompanyExpenses(context.role)) {
      return Future.value(
        const FailureResult<List<CompanyExpenseCategory>>(
          PermissionFailure(
            code: FailureCodes.permissionCompanyExpensesView,
            message: 'Company expenses access is not allowed.',
          ),
        ),
      );
    }

    return _repository.getCategories(
      companyId: context.companyId,
      includeInactive: params.includeInactive,
    );
  }
}

class GetCompanyExpensesUseCase
    implements UseCase<List<CompanyExpense>, GetCompanyExpensesParams> {
  final CompanyExpensesRepository _repository;

  const GetCompanyExpensesUseCase(this._repository);

  @override
  Future<Result<List<CompanyExpense>>> call(GetCompanyExpensesParams params) {
    final context = params.currentCompanyContext;
    if (!CompanyExpensesPermissionPolicy.canViewCompanyExpenses(context.role)) {
      return Future.value(
        const FailureResult<List<CompanyExpense>>(
          PermissionFailure(
            code: FailureCodes.permissionCompanyExpensesView,
            message: 'Company expenses access is not allowed.',
          ),
        ),
      );
    }

    return _repository.getCompanyExpenses(
      companyId: context.companyId,
      includeVoided: params.includeVoided,
    );
  }
}

class AddCompanyExpenseUseCase
    implements UseCase<CompanyExpense, AddCompanyExpenseParams> {
  final CompanyExpensesRepository _repository;

  const AddCompanyExpenseUseCase(this._repository);

  @override
  Future<Result<CompanyExpense>> call(AddCompanyExpenseParams params) {
    final failure = _validateWritableExpense(
      context: params.currentCompanyContext,
      categoryId: params.categoryId,
      amount: params.amount,
    );
    if (failure != null) return Future.value(FailureResult(failure));

    return _repository.addCompanyExpense(
      actorRole: params.currentCompanyContext.role.name,
      data: _writeData(
        context: params.currentCompanyContext,
        categoryId: params.categoryId,
        driverId: params.driverId,
        tractorHeadId: params.tractorHeadId,
        trailerId: params.trailerId,
        tripId: params.tripId,
        amount: params.amount,
        expenseDate: params.expenseDate,
        referenceNumber: params.referenceNumber,
        notes: params.notes,
      ),
    );
  }
}

class UpdateCompanyExpenseUseCase
    implements UseCase<CompanyExpense, UpdateCompanyExpenseParams> {
  final CompanyExpensesRepository _repository;

  const UpdateCompanyExpenseUseCase(this._repository);

  @override
  Future<Result<CompanyExpense>> call(UpdateCompanyExpenseParams params) {
    final expenseId = _optional(params.expenseId);
    if (expenseId == null) {
      return Future.value(
        const FailureResult<CompanyExpense>(
          ValidationFailure(
            code: FailureCodes.validationCompanyExpenseIdRequired,
            message: 'Company expense id is required.',
          ),
        ),
      );
    }

    final failure = _validateWritableExpense(
      context: params.currentCompanyContext,
      categoryId: params.categoryId,
      amount: params.amount,
    );
    if (failure != null) return Future.value(FailureResult(failure));

    return _repository.updateCompanyExpense(
      id: expenseId,
      actorRole: params.currentCompanyContext.role.name,
      data: _writeData(
        context: params.currentCompanyContext,
        categoryId: params.categoryId,
        driverId: params.driverId,
        tractorHeadId: params.tractorHeadId,
        trailerId: params.trailerId,
        tripId: params.tripId,
        amount: params.amount,
        expenseDate: params.expenseDate,
        referenceNumber: params.referenceNumber,
        notes: params.notes,
      ),
    );
  }
}

class VoidCompanyExpenseUseCase
    implements UseCase<CompanyExpense, VoidCompanyExpenseParams> {
  final CompanyExpensesRepository _repository;

  const VoidCompanyExpenseUseCase(this._repository);

  @override
  Future<Result<CompanyExpense>> call(VoidCompanyExpenseParams params) {
    final context = params.currentCompanyContext;
    if (!CompanyExpensesPermissionPolicy.canManageCompanyExpenses(context.role)) {
      return Future.value(
        const FailureResult<CompanyExpense>(
          PermissionFailure(
            code: FailureCodes.permissionCompanyExpensesManagement,
            message: 'Company expenses management is not allowed.',
          ),
        ),
      );
    }

    final expenseId = _optional(params.expenseId);
    if (expenseId == null) {
      return Future.value(
        const FailureResult<CompanyExpense>(
          ValidationFailure(
            code: FailureCodes.validationCompanyExpenseIdRequired,
            message: 'Company expense id is required.',
          ),
        ),
      );
    }

    return _repository.voidCompanyExpense(
      actorRole: context.role.name,
      data: CompanyExpenseVoidData(
        companyId: context.companyId,
        expenseId: expenseId,
        reason: _optional(params.reason),
      ),
    );
  }
}

Failure? _validateWritableExpense({
  required CurrentCompanyContext context,
  required String categoryId,
  required double amount,
}) {
  if (!CompanyExpensesPermissionPolicy.canManageCompanyExpenses(context.role)) {
    return const PermissionFailure(
      code: FailureCodes.permissionCompanyExpensesManagement,
      message: 'Company expenses management is not allowed.',
    );
  }

  if (_optional(categoryId) == null) {
    return const ValidationFailure(
      code: FailureCodes.validationCompanyExpenseCategoryRequired,
      message: 'Company expense category is required.',
    );
  }

  if (amount <= 0) {
    return const ValidationFailure(
      code: FailureCodes.validationCompanyExpenseAmountPositive,
      message: 'Company expense amount must be greater than zero.',
    );
  }

  return null;
}

CompanyExpenseWriteData _writeData({
  required CurrentCompanyContext context,
  required String categoryId,
  required String? driverId,
  required String? tractorHeadId,
  required String? trailerId,
  required String? tripId,
  required double amount,
  required DateTime expenseDate,
  required String? referenceNumber,
  required String? notes,
}) {
  return CompanyExpenseWriteData(
    companyId: context.companyId,
    categoryId: categoryId.trim(),
    driverId: _optional(driverId),
    tractorHeadId: _optional(tractorHeadId),
    trailerId: _optional(trailerId),
    tripId: _optional(tripId),
    amount: amount,
    expenseDate: expenseDate,
    referenceNumber: _optional(referenceNumber),
    notes: _optional(notes),
  );
}

String? _optional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
