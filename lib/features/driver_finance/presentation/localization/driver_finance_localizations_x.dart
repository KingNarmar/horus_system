import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/driver_financial_movement_type.dart';
import '../../domain/entities/driver_balance_activity_entry.dart';

extension DriverFinanceLocalizationsX on AppLocalizations {
  String driverActivityKindLabel(DriverBalanceActivityKind kind) {
    return switch (kind) {
      DriverBalanceActivityKind.advance => driverMovementTypeAdvance,
      DriverBalanceActivityKind.driverCharge => driverMovementTypeDriverCharge,
      DriverBalanceActivityKind.cashReturn => driverMovementTypeCashReturn,
      DriverBalanceActivityKind.driverPaidTripExpense =>
        driverBalanceActivityDriverPaidExpense,
    };
  }

  String driverActivitySourceLabel(DriverBalanceActivitySource source) {
    return switch (source) {
      DriverBalanceActivitySource.financialMovement =>
        driverBalanceActivityFinancialMovementSource,
      DriverBalanceActivitySource.tripExpense =>
        driverBalanceActivityTripExpenseSource,
    };
  }

  String driverMovementTypeLabel(DriverFinancialMovementType type) {
    return switch (type) {
      DriverFinancialMovementType.advance => driverMovementTypeAdvance,
      DriverFinancialMovementType.driverCharge =>
        driverMovementTypeDriverCharge,
      DriverFinancialMovementType.cashReturn => driverMovementTypeCashReturn,
    };
  }

  String driverBalanceLabel(double balance) {
    final amount = balance.abs().toStringAsFixed(2);

    if (balance < 0) {
      return driverBalanceDriverOwesCompany(amount);
    }

    if (balance > 0) {
      return driverBalanceCompanyOwesDriver(amount);
    }

    return driverBalanceSettled;
  }
}
