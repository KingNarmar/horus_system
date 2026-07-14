import '../../../../core/domain/services/driver_balance_calculator.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../entities/driver_settlement_calculation_input.dart';
import '../entities/driver_settlement_period.dart';
import '../entities/driver_settlement_source_snapshot.dart';
import '../policies/driver_settlements_permission_policy.dart';
import 'driver_settlement_params.dart';

abstract final class DriverSettlementUseCaseValidation {
  static const _balanceCalculator = DriverBalanceCalculator();

  static Failure? validateCalculationParams(
    DriverSettlementCalculationParams params, {
    bool requireManage = false,
  }) {
    final context = params.currentCompanyContext;
    final hasPermission = requireManage
        ? DriverSettlementsPermissionPolicy.canManageDriverSettlements(
            context.role,
          )
        : DriverSettlementsPermissionPolicy.canViewDriverSettlements(
            context.role,
          );

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

    if (optional(params.driverId) == null) {
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

  static Failure? validateBalanceRecovery({
    required DriverSettlementCalculationParams params,
    required DriverSettlementSourceSnapshot snapshot,
  }) {
    final balanceBeforeRecovery = _balanceCalculator.calculate(
      openingBalance: snapshot.openingDriverBalance,
      advancesReceived: snapshot.advancesTotal,
      driverCharges:
          snapshot.deductionsTotal + params.settlementDeductionsTotal,
      creditedTripExpenses: snapshot.driverPaidTripExpensesTotal,
      cashReturned: snapshot.returnedCashTotal,
    );
    final outstandingDebt = balanceBeforeRecovery < 0
        ? _balanceCalculator.roundMoney(-balanceBeforeRecovery)
        : 0.0;
    final requestedRecovery = _balanceCalculator.roundMoney(
      params.balanceDeductionApplied,
    );

    if (requestedRecovery > outstandingDebt) {
      return const ValidationFailure(
        code: FailureCodes.validationDriverSettlementBalanceRecoveryExceedsDebt,
        message: 'Driver balance recovery cannot exceed outstanding debt.',
      );
    }

    return null;
  }

  static DriverSettlementCalculationInput calculationInput({
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

  static String? optional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
