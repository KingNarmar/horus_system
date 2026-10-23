abstract final class DriverSettlementFailureCodes {
  static const validationDraftPayloadInvalid =
      'validation_driver_settlement_draft_payload_invalid';
  static const validationAmountInvalid =
      'validation_driver_settlement_amount_invalid';
  static const conflictCompensationCurrencyMismatch =
      'conflict_driver_settlement_compensation_currency_mismatch';
  static const conflictExpenseSourceInvalid =
      'conflict_driver_settlement_expense_source_invalid';
  static const conflictSourceSnapshotChanged =
      'conflict_driver_settlement_source_snapshot_changed';
  static const conflictCompensationChanged =
      'conflict_driver_settlement_compensation_changed';
  static const validationExactMoneyMismatch =
      'validation_driver_settlement_exact_money_mismatch';
  static const validationFinancialTotalsMismatch =
      'validation_driver_settlement_financial_totals_mismatch';
  static const conflictPeriodExists =
      'conflict_driver_settlement_period_exists';
}
