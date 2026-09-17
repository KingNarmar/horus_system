import '../../../../core/domain/services/driver_balance_calculator.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../entities/driver_settlement_driver_option.dart';
import '../entities/driver_settlement_money_calculation_input.dart';
import '../entities/driver_settlement_money_source_snapshot.dart';
import '../entities/driver_settlement_period.dart';
import '../entities/driver_settlement_resolved_money_inputs.dart';
import '../policies/driver_settlements_permission_policy.dart';
import '../repositories/driver_settlements_repository.dart';
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

    return null;
  }

  static Future<Failure?> validateActiveDriver({
    required DriverSettlementsRepository repository,
    required String companyId,
    required String driverId,
  }) async {
    final result = await repository.getDriverOptionById(
      companyId: companyId,
      driverId: driverId,
    );

    if (result is FailureResult<DriverSettlementDriverOption?>) {
      return result.failure;
    }

    final driver = result.dataOrNull;
    if (driver == null) {
      return const ValidationFailure(
        code: FailureCodes.validationDriverSettlementDriverNotFound,
        message: 'Driver was not found in the current company.',
      );
    }

    if (!driver.isActive) {
      return const ValidationFailure(
        code: FailureCodes.validationDriverSettlementDriverInactive,
        message: 'Inactive drivers cannot be used for new settlements.',
      );
    }

    return null;
  }

  static Failure? validateBalanceRecoveryMoney({
    required DriverSettlementResolvedMoneyInputs resolvedInputs,
    required DriverSettlementMoneySourceSnapshot snapshot,
  }) {
    final zero = Money(
      minorUnits: 0,
      currency: resolvedInputs.currencyConfiguration.currency,
    );
    final balanceBeforeRecovery = _balanceCalculator.calculateMoney(
      openingBalance: snapshot.openingDriverBalance,
      advancesReceived: snapshot.advancesTotal,
      driverCharges: snapshot.deductionsTotal.add(
        resolvedInputs.settlementDeductionsTotal,
      ),
      creditedTripExpenses: snapshot.driverPaidTripExpensesTotal,
      cashReturned: snapshot.returnedCashTotal,
      salaryRecovery: zero,
    );
    final outstandingDebtMinorUnits = balanceBeforeRecovery.isNegative
        ? -balanceBeforeRecovery.minorUnits
        : 0;

    if (resolvedInputs.balanceDeductionApplied.minorUnits >
        outstandingDebtMinorUnits) {
      return const ValidationFailure(
        code: FailureCodes.validationDriverSettlementBalanceRecoveryExceedsDebt,
        message: 'Driver balance recovery cannot exceed outstanding debt.',
      );
    }

    return null;
  }

  static DriverSettlementMoneyCalculationInput calculationMoneyInput({
    required DriverSettlementResolvedMoneyInputs resolvedInputs,
    required DriverSettlementMoneySourceSnapshot snapshot,
  }) {
    return DriverSettlementMoneyCalculationInput(
      openingDriverBalance: snapshot.openingDriverBalance,
      advancesTotal: snapshot.advancesTotal,
      driverPaidTripExpensesTotal: snapshot.driverPaidTripExpensesTotal,
      returnedCashTotal: snapshot.returnedCashTotal,
      deductionsTotal: snapshot.deductionsTotal,
      settlementDeductionsTotal: resolvedInputs.settlementDeductionsTotal,
      grossSalary: resolvedInputs.grossSalary,
      salaryDeductionsTotal: resolvedInputs.salaryDeductionsTotal,
      balanceDeductionApplied: resolvedInputs.balanceDeductionApplied,
    );
  }

  static String? optional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
