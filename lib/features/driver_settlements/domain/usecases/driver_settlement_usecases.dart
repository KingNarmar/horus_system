import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver_settlement.dart';
import '../entities/driver_settlement_calculation_input.dart';
import '../entities/driver_settlement_period.dart';
import '../entities/driver_settlement_preview.dart';
import '../entities/driver_settlement_source_snapshot.dart';
import '../entities/driver_settlement_write_data.dart';
import '../policies/driver_settlements_permission_policy.dart';
import '../repositories/driver_settlements_repository.dart';
import '../services/driver_settlement_calculator.dart';

class GetDriverSettlementsParams {
  final CurrentCompanyContext currentCompanyContext;
  final String? driverId;
  final bool includeVoided;

  const GetDriverSettlementsParams({
    required this.currentCompanyContext,
    this.driverId,
    this.includeVoided = false,
  });
}

class GetDriverSettlementDetailsParams {
  final CurrentCompanyContext currentCompanyContext;
  final String settlementId;

  const GetDriverSettlementDetailsParams({
    required this.currentCompanyContext,
    required this.settlementId,
  });
}

class DriverSettlementCalculationParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double grossSalary;
  final double salaryDeductionsTotal;
  final double balanceDeductionApplied;
  final double settlementDeductionsTotal;
  final String? notes;

  const DriverSettlementCalculationParams({
    required this.currentCompanyContext,
    required this.driverId,
    required this.periodStart,
    required this.periodEnd,
    this.grossSalary = 0,
    this.salaryDeductionsTotal = 0,
    this.balanceDeductionApplied = 0,
    this.settlementDeductionsTotal = 0,
    this.notes,
  });
}

class CreateDriverSettlementDraftParams extends DriverSettlementCalculationParams {
  const CreateDriverSettlementDraftParams({
    required super.currentCompanyContext,
    required super.driverId,
    required super.periodStart,
    required super.periodEnd,
    super.grossSalary,
    super.salaryDeductionsTotal,
    super.balanceDeductionApplied,
    super.settlementDeductionsTotal,
    super.notes,
  });
}

class FinalizeDriverSettlementParams {
  final CurrentCompanyContext currentCompanyContext;
  final String settlementId;

  const FinalizeDriverSettlementParams({
    required this.currentCompanyContext,
    required this.settlementId,
  });
}

class VoidDriverSettlementParams {
  final CurrentCompanyContext currentCompanyContext;
  final String settlementId;
  final String reason;

  const VoidDriverSettlementParams({
    required this.currentCompanyContext,
    required this.settlementId,
    required this.reason,
  });
}

class GetDriverSettlementsUseCase
    implements UseCase<List<DriverSettlement>, GetDriverSettlementsParams> {
  final DriverSettlementsRepository _repository;

  const GetDriverSettlementsUseCase(this._repository);

  @override
  Future<Result<List<DriverSettlement>>> call(GetDriverSettlementsParams params) {
    final context = params.currentCompanyContext;
    if (!DriverSettlementsPermissionPolicy.canViewDriverSettlements(
      context.role,
    )) {
      return Future.value(
        const FailureResult<List<DriverSettlement>>(
          PermissionFailure(
            code: FailureCodes.permissionDriverSettlementsView,
            message: 'Driver settlements access is not allowed.',
          ),
        ),
      );
    }

    return _repository.getDriverSettlements(
      companyId: context.companyId,
      driverId: _optional(params.driverId),
      includeVoided: params.includeVoided,
    );
  }
}

class GetDriverSettlementDetailsUseCase
    implements UseCase<DriverSettlement, GetDriverSettlementDetailsParams> {
  final DriverSettlementsRepository _repository;

  const GetDriverSettlementDetailsUseCase(this._repository);

  @override
  Future<Result<DriverSettlement>> call(GetDriverSettlementDetailsParams params) {
    final context = params.currentCompanyContext;
    if (!DriverSettlementsPermissionPolicy.canViewDriverSettlements(
      context.role,
    )) {
      return Future.value(
        const FailureResult<DriverSettlement>(
          PermissionFailure(
            code: FailureCodes.permissionDriverSettlementsView,
            message: 'Driver settlements access is not allowed.',
          ),
        ),
      );
    }

    final settlementId = _optional(params.settlementId);
    if (settlementId == null) {
      return Future.value(
        const FailureResult<DriverSettlement>(
          ValidationFailure(
            code: FailureCodes.validationDriverSettlementIdRequired,
            message: 'Driver settlement id is required.',
          ),
        ),
      );
    }

    return _repository.getDriverSettlementById(
      companyId: context.companyId,
      settlementId: settlementId,
    );
  }
}

class CalculateDriverSettlementPreviewUseCase
    implements
        UseCase<DriverSettlementPreview, DriverSettlementCalculationParams> {
  final DriverSettlementsRepository _repository;
  final DriverSettlementCalculator _calculator;

  const CalculateDriverSettlementPreviewUseCase(
    this._repository, {
    DriverSettlementCalculator calculator = const DriverSettlementCalculator(),
  }) : _calculator = calculator;

  @override
  Future<Result<DriverSettlementPreview>> call(
    DriverSettlementCalculationParams params,
  ) async {
    final validation = _validateCalculationParams(params);
    if (validation != null) return FailureResult(validation);

    final context = params.currentCompanyContext;
    final driverId = params.driverId.trim();
    final period = DriverSettlementPeriod(
      start: params.periodStart,
      end: params.periodEnd,
    );

    final snapshotResult = await _repository.getSettlementSourceSnapshot(
      companyId: context.companyId,
      driverId: driverId,
      period: period,
    );

    if (snapshotResult is FailureResult<DriverSettlementSourceSnapshot>) {
      return FailureResult(snapshotResult.failure);
    }

    final snapshot = snapshotResult.dataOrNull ??
        const DriverSettlementSourceSnapshot();
    final calculation = _calculator.calculate(
      _calculationInput(params: params, snapshot: snapshot),
    );

    return Success(
      DriverSettlementPreview(
        companyId: context.companyId,
        driverId: driverId,
        period: period,
        calculation: calculation,
        items: snapshot.sourceItems,
      ),
    );
  }
}

class CreateDriverSettlementDraftUseCase
    implements UseCase<DriverSettlement, CreateDriverSettlementDraftParams> {
  final DriverSettlementsRepository _repository;
  final DriverSettlementCalculator _calculator;

  const CreateDriverSettlementDraftUseCase(
    this._repository, {
    DriverSettlementCalculator calculator = const DriverSettlementCalculator(),
  }) : _calculator = calculator;

  @override
  Future<Result<DriverSettlement>> call(
    CreateDriverSettlementDraftParams params,
  ) async {
    final validation = _validateCalculationParams(params, requireManage: true);
    if (validation != null) return FailureResult(validation);

    final context = params.currentCompanyContext;
    final driverId = params.driverId.trim();
    final period = DriverSettlementPeriod(
      start: params.periodStart,
      end: params.periodEnd,
    );

    final snapshotResult = await _repository.getSettlementSourceSnapshot(
      companyId: context.companyId,
      driverId: driverId,
      period: period,
    );

    if (snapshotResult is FailureResult<DriverSettlementSourceSnapshot>) {
      return FailureResult(snapshotResult.failure);
    }

    final snapshot = snapshotResult.dataOrNull ??
        const DriverSettlementSourceSnapshot();
    final calculation = _calculator.calculate(
      _calculationInput(params: params, snapshot: snapshot),
    );

    return _repository.createDraft(
      actorRole: context.role.name,
      data: DriverSettlementDraftWriteData(
        companyId: context.companyId,
        driverId: driverId,
        period: period,
        calculation: calculation,
        items: snapshot.sourceItems,
        notes: _optional(params.notes),
      ),
    );
  }
}

class FinalizeDriverSettlementUseCase
    implements UseCase<DriverSettlement, FinalizeDriverSettlementParams> {
  final DriverSettlementsRepository _repository;

  const FinalizeDriverSettlementUseCase(this._repository);

  @override
  Future<Result<DriverSettlement>> call(FinalizeDriverSettlementParams params) {
    final context = params.currentCompanyContext;
    if (!DriverSettlementsPermissionPolicy.canFinalizeDriverSettlements(
      context.role,
    )) {
      return Future.value(
        const FailureResult<DriverSettlement>(
          PermissionFailure(
            code: FailureCodes.permissionDriverSettlementsManagement,
            message: 'Driver settlements management is not allowed.',
          ),
        ),
      );
    }

    final settlementId = _optional(params.settlementId);
    if (settlementId == null) {
      return Future.value(
        const FailureResult<DriverSettlement>(
          ValidationFailure(
            code: FailureCodes.validationDriverSettlementIdRequired,
            message: 'Driver settlement id is required.',
          ),
        ),
      );
    }

    return _repository.finalizeSettlement(
      actorRole: context.role.name,
      data: DriverSettlementFinalizeData(
        companyId: context.companyId,
        settlementId: settlementId,
      ),
    );
  }
}

class VoidDriverSettlementUseCase
    implements UseCase<DriverSettlement, VoidDriverSettlementParams> {
  final DriverSettlementsRepository _repository;

  const VoidDriverSettlementUseCase(this._repository);

  @override
  Future<Result<DriverSettlement>> call(VoidDriverSettlementParams params) {
    final context = params.currentCompanyContext;
    if (!DriverSettlementsPermissionPolicy.canVoidDriverSettlements(
      context.role,
    )) {
      return Future.value(
        const FailureResult<DriverSettlement>(
          PermissionFailure(
            code: FailureCodes.permissionDriverSettlementsManagement,
            message: 'Driver settlements management is not allowed.',
          ),
        ),
      );
    }

    final settlementId = _optional(params.settlementId);
    if (settlementId == null) {
      return Future.value(
        const FailureResult<DriverSettlement>(
          ValidationFailure(
            code: FailureCodes.validationDriverSettlementIdRequired,
            message: 'Driver settlement id is required.',
          ),
        ),
      );
    }

    final reason = _optional(params.reason);
    if (reason == null) {
      return Future.value(
        const FailureResult<DriverSettlement>(
          ValidationFailure(
            code: FailureCodes.validationDriverSettlementVoidReasonRequired,
            message: 'Driver settlement void reason is required.',
          ),
        ),
      );
    }

    return _repository.voidSettlement(
      actorRole: context.role.name,
      data: DriverSettlementVoidData(
        companyId: context.companyId,
        settlementId: settlementId,
        reason: reason,
      ),
    );
  }
}

Failure? _validateCalculationParams(
  DriverSettlementCalculationParams params, {
  bool requireManage = false,
}) {
  final context = params.currentCompanyContext;
  final hasPermission = requireManage
      ? DriverSettlementsPermissionPolicy.canManageDriverSettlements(
          context.role,
        )
      : DriverSettlementsPermissionPolicy.canViewDriverSettlements(context.role);

  if (!hasPermission) {
    return PermissionFailure(
      code: requireManage
          ? FailureCodes.permissionDriverSettlementsManagement
          : FailureCodes.permissionDriverSettlementsView,
      message: requireManage
          ? 'Driver settlements management is not allowed.'
          : 'Driver settlements access is not allowed.',
    );
  }

  if (_optional(params.driverId) == null) {
    return const ValidationFailure(
      code: FailureCodes.validationDriverIdRequired,
      message: 'Driver id is required.',
    );
  }

  final period = DriverSettlementPeriod(
    start: params.periodStart,
    end: params.periodEnd,
  );
  if (!period.isValid) {
    return const ValidationFailure(
      code: FailureCodes.validationDriverSettlementPeriodInvalid,
      message: 'Driver settlement period is invalid.',
    );
  }

  final amounts = <double>[
    params.grossSalary,
    params.salaryDeductionsTotal,
    params.balanceDeductionApplied,
    params.settlementDeductionsTotal,
  ];

  if (amounts.any((amount) => amount < 0)) {
    return const ValidationFailure(
      code: FailureCodes.validationDriverSettlementAmountNegative,
      message: 'Driver settlement amounts cannot be negative.',
    );
  }

  if (params.grossSalary -
          params.salaryDeductionsTotal -
          params.balanceDeductionApplied <
      0) {
    return const ValidationFailure(
      code: FailureCodes.validationDriverSettlementNetSalaryNegative,
      message: 'Driver settlement net salary cannot be negative.',
    );
  }

  return null;
}

DriverSettlementCalculationInput _calculationInput({
  required DriverSettlementCalculationParams params,
  required DriverSettlementSourceSnapshot snapshot,
}) {
  return DriverSettlementCalculationInput(
    openingDriverBalance: snapshot.openingDriverBalance,
    advancesTotal: snapshot.advancesTotal,
    driverPaidTripExpensesTotal: snapshot.driverPaidTripExpensesTotal,
    returnedCashTotal: snapshot.returnedCashTotal,
    deductionsTotal: snapshot.deductionsTotal,
    settlementDeductionsTotal: params.settlementDeductionsTotal,
    grossSalary: params.grossSalary,
    salaryDeductionsTotal: params.salaryDeductionsTotal,
    balanceDeductionApplied: params.balanceDeductionApplied,
  );
}

String? _optional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
