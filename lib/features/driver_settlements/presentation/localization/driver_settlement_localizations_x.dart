import 'package:flutter/widgets.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../audit/presentation/localization/audit_display_localizations_x.dart';
import '../../domain/entities/driver_settlement_balance_direction.dart';
import '../../domain/entities/driver_settlement_item.dart';
import '../../domain/entities/driver_settlement_item_direction.dart';
import '../../domain/entities/driver_settlement_item_source_type.dart';
import '../../domain/entities/driver_settlement_status.dart';
import 'driver_settlements_localizations.dart';

extension DriverSettlementPresentationLocalizationsX on BuildContext {
  String localizedDriverSettlementFailure(Failure failure) {
    final strings = driverSettlementsL10n;
    return switch (failure.code) {
      FailureCodes.permissionDriverSettlementsView =>
        strings.permissionViewFailure,
      FailureCodes.permissionDriverSettlementsManagement =>
        strings.permissionManageFailure,
      FailureCodes.validationDriverSettlementIdRequired =>
        strings.settlementIdRequiredFailure,
      FailureCodes.validationDriverSettlementPeriodInvalid =>
        strings.periodInvalidFailure,
      FailureCodes.validationDriverSettlementAmountNegative =>
        strings.amountNegativeFailure,
      FailureCodes.validationDriverSettlementNetSalaryNegative =>
        strings.netSalaryNegativeFailure,
      FailureCodes.validationDriverSettlementBalanceRecoveryExceedsDebt =>
        strings.balanceRecoveryExceedsDebtFailure,
      FailureCodes.validationDriverSettlementDriverNotFound =>
        strings.driverNotFoundFailure,
      FailureCodes.validationDriverSettlementDriverInactive =>
        strings.driverInactiveFailure,
      FailureCodes.validationDriverSettlementVoidReasonRequired =>
        strings.voidReasonRequiredFailure,
      _ => l10n.localizedErrorMessage(failure),
    };
  }

  String driverSettlementStatusLabel(DriverSettlementStatus status) {
    final strings = driverSettlementsL10n;
    return switch (status) {
      DriverSettlementStatus.draft => strings.statusDraft,
      DriverSettlementStatus.finalized => strings.statusFinalized,
      DriverSettlementStatus.voided => strings.statusVoided,
    };
  }

  String driverSettlementBalanceDirectionLabel(
    DriverSettlementBalanceDirection direction,
  ) {
    final strings = driverSettlementsL10n;
    return switch (direction) {
      DriverSettlementBalanceDirection.driverOwesCompany =>
        strings.driverOwesCompany,
      DriverSettlementBalanceDirection.companyOwesDriver =>
        strings.companyOwesDriver,
      DriverSettlementBalanceDirection.settled => strings.balanceSettled,
    };
  }

  String driverSettlementItemLabel(DriverSettlementItem item) {
    final strings = driverSettlementsL10n;
    return switch (item.labelKey) {
      'driver_settlement_item_advance' => strings.itemAdvance,
      'driver_settlement_item_driver_charge' => strings.itemDriverCharge,
      'driver_settlement_item_cash_return' => strings.itemCashReturn,
      'driver_settlement_item_deduction' => strings.itemDriverCharge,
      'driver_settlement_item_trip_expense' => strings.itemTripExpense,
      _ => switch (item.sourceType) {
        DriverSettlementItemSourceType.driverFinancialMovement =>
          _driverFinancialMovementLabel(item, strings),
        DriverSettlementItemSourceType.tripExpense => strings.itemTripExpense,
        DriverSettlementItemSourceType.manualAdjustment =>
          strings.itemManualAdjustment,
      },
    };
  }

  String driverSettlementItemDirectionLabel(
    DriverSettlementItemDirection direction,
  ) {
    final strings = driverSettlementsL10n;
    return switch (direction) {
      DriverSettlementItemDirection.companyToDriver =>
        strings.directionCompanyToDriver,
      DriverSettlementItemDirection.driverToCompany =>
        strings.directionDriverToCompany,
      DriverSettlementItemDirection.neutral => strings.directionNeutral,
    };
  }

  String driverSettlementAuditDescription(AuditLog log) {
    final strings = driverSettlementsL10n;
    return switch (log.description) {
      'driver_settlement_created' => strings.auditCreated,
      'driver_settlement_finalized' => strings.auditFinalized,
      'driver_settlement_voided' => strings.auditVoided,
      _ => switch (log.metadata?['status']?.toString()) {
        'finalized' => strings.auditFinalized,
        'voided' => strings.auditVoided,
        _ => strings.auditCreated,
      },
    };
  }

  String localizedAuditRole(String? rawRole) {
    return l10n.auditRoleDisplayLabel(rawRole);
  }
}

String _driverFinancialMovementLabel(
  DriverSettlementItem item,
  DriverSettlementsLocalizations strings,
) {
  return switch (item.metadata['movement_type']?.toString()) {
    'advance' => strings.itemAdvance,
    'driver_charge' || 'deduction' => strings.itemDriverCharge,
    'cash_return' => strings.itemCashReturn,
    _ => strings.itemFinancialMovement,
  };
}
