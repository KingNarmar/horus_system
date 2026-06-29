import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver_balance.dart';
import '../entities/driver_financial_movement.dart';
import '../entities/driver_financial_movement_type.dart';
import '../entities/driver_financial_movement_write_data.dart';
import '../policies/driver_finance_permission_policy.dart';
import '../repositories/driver_finance_repository.dart';

class GetDriverMovementsParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;

  const GetDriverMovementsParams({
    required this.currentCompanyContext,
    required this.driverId,
  });
}

class AddDriverAdvanceParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final double amount;
  final DateTime movementDate;
  final String? notes;

  const AddDriverAdvanceParams({
    required this.currentCompanyContext,
    required this.driverId,
    required this.amount,
    required this.movementDate,
    this.notes,
  });
}

class AddDriverDeductionParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final String? tripId;
  final double amount;
  final DateTime movementDate;
  final String? notes;

  const AddDriverDeductionParams({
    required this.currentCompanyContext,
    required this.driverId,
    required this.amount,
    required this.movementDate,
    this.tripId,
    this.notes,
  });
}

class CalculateDriverBalanceParams {
  final String companyId;
  final String driverId;
  final List<DriverFinancialMovement> movements;

  const CalculateDriverBalanceParams({
    required this.companyId,
    required this.driverId,
    required this.movements,
  });
}

class GetDriverMovementsUseCase
    implements UseCase<List<DriverFinancialMovement>, GetDriverMovementsParams> {
  final DriverFinanceRepository _repository;

  const GetDriverMovementsUseCase(this._repository);

  @override
  Future<Result<List<DriverFinancialMovement>>> call(
    GetDriverMovementsParams params,
  ) {
    final context = params.currentCompanyContext;

    if (!DriverFinancePermissionPolicy.canViewDriverFinance(context.role)) {
      return Future.value(
        const FailureResult<List<DriverFinancialMovement>>(
          PermissionFailure(
            code: FailureCodes.permissionDriverFinanceView,
            message: 'Driver finance access is not allowed.',
          ),
        ),
      );
    }

    final driverId = _optional(params.driverId);
    if (driverId == null) {
      return Future.value(
        const FailureResult<List<DriverFinancialMovement>>(
          ValidationFailure(
            code: FailureCodes.validationDriverIdRequired,
            message: 'Driver id is required.',
          ),
        ),
      );
    }

    return _repository.getDriverMovements(
      companyId: context.companyId,
      driverId: driverId,
    );
  }
}

class AddDriverAdvanceUseCase
    implements UseCase<DriverFinancialMovement, AddDriverAdvanceParams> {
  final DriverFinanceRepository _repository;

  const AddDriverAdvanceUseCase(this._repository);

  @override
  Future<Result<DriverFinancialMovement>> call(AddDriverAdvanceParams params) {
    return _addMovement(
      repository: _repository,
      context: params.currentCompanyContext,
      driverId: params.driverId,
      tripId: null,
      type: DriverFinancialMovementType.advance,
      amount: params.amount,
      movementDate: params.movementDate,
      notes: params.notes,
    );
  }
}

class AddDriverDeductionUseCase
    implements UseCase<DriverFinancialMovement, AddDriverDeductionParams> {
  final DriverFinanceRepository _repository;

  const AddDriverDeductionUseCase(this._repository);

  @override
  Future<Result<DriverFinancialMovement>> call(AddDriverDeductionParams params) {
    return _addMovement(
      repository: _repository,
      context: params.currentCompanyContext,
      driverId: params.driverId,
      tripId: params.tripId,
      type: DriverFinancialMovementType.deduction,
      amount: params.amount,
      movementDate: params.movementDate,
      notes: params.notes,
    );
  }
}

class CalculateDriverBalanceUseCase
    implements UseCase<DriverBalance, CalculateDriverBalanceParams> {
  const CalculateDriverBalanceUseCase();

  @override
  Future<Result<DriverBalance>> call(CalculateDriverBalanceParams params) {
    var totalAdvances = 0.0;
    var totalDeductions = 0.0;

    for (final movement in params.movements) {
      if (movement.type.isAdvance) {
        totalAdvances += movement.amount;
      } else if (movement.type.isDeduction) {
        totalDeductions += movement.amount;
      }
    }

    return Future.value(
      Success(
        DriverBalance(
          companyId: params.companyId,
          driverId: params.driverId,
          totalAdvances: totalAdvances,
          totalDeductions: totalDeductions,
        ),
      ),
    );
  }
}

Future<Result<DriverFinancialMovement>> _addMovement({
  required DriverFinanceRepository repository,
  required CurrentCompanyContext context,
  required String driverId,
  required String? tripId,
  required DriverFinancialMovementType type,
  required double amount,
  required DateTime movementDate,
  required String? notes,
}) {
  final failure = _validateWritableMovement(
    context: context,
    driverId: driverId,
    amount: amount,
  );

  if (failure != null) return Future.value(FailureResult(failure));

  return repository.addDriverMovement(
    actorRole: context.role.value,
    data: DriverFinancialMovementWriteData(
      companyId: context.companyId,
      driverId: driverId.trim(),
      tripId: type.isDeduction ? _optional(tripId) : null,
      type: type,
      amount: amount,
      movementDate: movementDate,
      notes: _optional(notes),
    ),
  );
}

Failure? _validateWritableMovement({
  required CurrentCompanyContext context,
  required String driverId,
  required double amount,
}) {
  if (!DriverFinancePermissionPolicy.canManageDriverFinance(context.role)) {
    return const PermissionFailure(
      code: FailureCodes.permissionDriverFinanceManagement,
      message: 'Driver finance management is not allowed.',
    );
  }

  if (_optional(driverId) == null) {
    return const ValidationFailure(
      code: FailureCodes.validationDriverIdRequired,
      message: 'Driver id is required.',
    );
  }

  if (amount <= 0) {
    return const ValidationFailure(
      code: FailureCodes.validationDriverFinanceAmountPositive,
      message: 'Driver financial movement amount must be greater than zero.',
    );
  }

  return null;
}

String? _optional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
