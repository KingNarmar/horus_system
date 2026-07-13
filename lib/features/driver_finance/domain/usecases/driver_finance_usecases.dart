import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver_balance.dart';
import '../entities/driver_finance_trip_option.dart';
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

class GetDriverTripOptionsParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;

  const GetDriverTripOptionsParams({
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

class AddDriverChargeParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final String? tripId;
  final double amount;
  final DateTime movementDate;
  final String? notes;

  const AddDriverChargeParams({
    required this.currentCompanyContext,
    required this.driverId,
    required this.amount,
    required this.movementDate,
    this.tripId,
    this.notes,
  });
}

@Deprecated('Use AddDriverChargeParams instead.')
typedef AddDriverDeductionParams = AddDriverChargeParams;

class AddDriverCashReturnParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final double amount;
  final DateTime movementDate;
  final String? notes;

  const AddDriverCashReturnParams({
    required this.currentCompanyContext,
    required this.driverId,
    required this.amount,
    required this.movementDate,
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
    implements
        UseCase<List<DriverFinancialMovement>, GetDriverMovementsParams> {
  final DriverFinanceRepository _repository;

  const GetDriverMovementsUseCase(this._repository);

  @override
  Future<Result<List<DriverFinancialMovement>>> call(
    GetDriverMovementsParams params,
  ) {
    final driverId = _validViewDriverId(
      params.currentCompanyContext,
      params.driverId,
    );
    if (driverId is FailureResult<String>) {
      return Future.value(FailureResult(driverId.failure));
    }

    return _repository.getDriverMovements(
      companyId: params.currentCompanyContext.companyId,
      driverId: (driverId as Success<String>).data,
    );
  }
}

class GetDriverTripOptionsUseCase
    implements
        UseCase<List<DriverFinanceTripOption>, GetDriverTripOptionsParams> {
  final DriverFinanceRepository _repository;

  const GetDriverTripOptionsUseCase(this._repository);

  @override
  Future<Result<List<DriverFinanceTripOption>>> call(
    GetDriverTripOptionsParams params,
  ) {
    final driverId = _validViewDriverId(
      params.currentCompanyContext,
      params.driverId,
    );
    if (driverId is FailureResult<String>) {
      return Future.value(FailureResult(driverId.failure));
    }

    return _repository.getDriverTripOptions(
      companyId: params.currentCompanyContext.companyId,
      driverId: (driverId as Success<String>).data,
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

class AddDriverChargeUseCase
    implements UseCase<DriverFinancialMovement, AddDriverChargeParams> {
  final DriverFinanceRepository _repository;

  const AddDriverChargeUseCase(this._repository);

  @override
  Future<Result<DriverFinancialMovement>> call(AddDriverChargeParams params) {
    return _addMovement(
      repository: _repository,
      context: params.currentCompanyContext,
      driverId: params.driverId,
      tripId: params.tripId,
      type: DriverFinancialMovementType.driverCharge,
      amount: params.amount,
      movementDate: params.movementDate,
      notes: params.notes,
    );
  }
}

@Deprecated('Use AddDriverChargeUseCase instead.')
typedef AddDriverDeductionUseCase = AddDriverChargeUseCase;

class AddDriverCashReturnUseCase
    implements UseCase<DriverFinancialMovement, AddDriverCashReturnParams> {
  final DriverFinanceRepository _repository;

  const AddDriverCashReturnUseCase(this._repository);

  @override
  Future<Result<DriverFinancialMovement>> call(
    AddDriverCashReturnParams params,
  ) {
    return _addMovement(
      repository: _repository,
      context: params.currentCompanyContext,
      driverId: params.driverId,
      tripId: null,
      type: DriverFinancialMovementType.cashReturn,
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
    var totalDriverCharges = 0.0;
    var totalCashReturns = 0.0;

    for (final movement in params.movements) {
      if (movement.type.isAdvance) {
        totalAdvances += movement.amount;
      } else if (movement.type.isDriverCharge) {
        totalDriverCharges += movement.amount;
      } else if (movement.type.isCashReturn) {
        totalCashReturns += movement.amount;
      }
    }

    return Future.value(
      Success(
        DriverBalance(
          companyId: params.companyId,
          driverId: params.driverId,
          totalAdvances: totalAdvances,
          totalDriverCharges: totalDriverCharges,
          totalCashReturns: totalCashReturns,
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
    actorRole: context.role.name,
    data: DriverFinancialMovementWriteData(
      companyId: context.companyId,
      driverId: driverId.trim(),
      tripId: type.canLinkTrip ? _optional(tripId) : null,
      type: type,
      amount: amount,
      movementDate: movementDate,
      notes: _optional(notes),
    ),
  );
}

Result<String> _validViewDriverId(
  CurrentCompanyContext context,
  String driverId,
) {
  if (!DriverFinancePermissionPolicy.canViewDriverFinance(context.role)) {
    return const FailureResult<String>(
      PermissionFailure(
        code: FailureCodes.permissionDriverFinanceView,
        message: 'Driver finance access is not allowed.',
      ),
    );
  }

  final value = _optional(driverId);
  if (value == null) {
    return const FailureResult<String>(
      ValidationFailure(
        code: FailureCodes.validationDriverIdRequired,
        message: 'Driver id is required.',
      ),
    );
  }

  return Success(value);
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
