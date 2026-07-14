import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/driver_financial_movement_type.dart';

extension DriverFinanceLocalizationsX on AppLocalizations {
  String driverMovementTypeLabel(DriverFinancialMovementType type) {
    return switch (type) {
      DriverFinancialMovementType.advance => driverMovementTypeAdvance,
      DriverFinancialMovementType.driverCharge => driverMovementTypeDeduction,
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
