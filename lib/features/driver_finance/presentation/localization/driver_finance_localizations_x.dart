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
}
