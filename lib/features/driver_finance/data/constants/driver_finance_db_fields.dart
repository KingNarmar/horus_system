abstract final class DriverFinanceDbTables {
  static const driverFinancialMovements = 'driver_financial_movements';
  static const trips = 'trips';
  static const expenseLedgerEntries = 'expense_ledger_entries';
}

abstract final class DriverFinanceDbFunctions {
  static const getBalanceCheckpoint = 'get_driver_balance_checkpoint_v2';
}

abstract final class DriverFinanceDbFields {
  static const driverId = 'driver_id';
  static const tripId = 'trip_id';
  static const movementType = 'movement_type';
  static const amount = 'amount';
  static const amountMinorUnits = 'amount_minor_units';
  static const currencyCode = 'currency_code';
  static const currencyFractionDigits = 'currency_fraction_digits';
  static const movementDate = 'movement_date';
  static const expenseDate = 'expense_date';
  static const fundingSource = 'funding_source';
  static const notes = 'notes';
  static const isVoided = 'is_voided';
  static const originKind = 'origin_kind';
  static const originId = 'origin_id';

  static const checkpointSettlementId = 'settlement_id';
  static const checkpointPeriodEnd = 'period_end';
  static const checkpointSnapshotCreatedAt = 'snapshot_created_at';
  static const checkpointClosingBalanceMinorUnits =
      'closing_driver_balance_minor_units';

  static const parameterCompanyId = 'p_company_id';
  static const parameterDriverId = 'p_driver_id';
  static const parameterBeforeExclusive = 'p_before_exclusive';
}

abstract final class DriverFinanceDbValues {
  static const movementAdvance = 'advance';
  static const movementDriverCharge = 'driver_charge';
  static const movementCashReturn = 'cash_return';
  static const fundingSourceDriverAdvance = 'driver_advance';
  static const fundingSourceDriverCash = 'driver_cash';
}
