abstract final class DriverFinanceDbTables {
  static const driverFinancialMovements = 'driver_financial_movements';
  static const trips = 'trips';
  static const tripExpenses = 'trip_expenses';
}

abstract final class DriverFinanceDbFunctions {
  static const getBalanceCheckpoint = 'get_driver_balance_checkpoint';
}

abstract final class DriverFinanceDbFields {
  static const driverId = 'driver_id';
  static const tripId = 'trip_id';
  static const movementType = 'movement_type';
  static const amount = 'amount';
  static const movementDate = 'movement_date';
  static const expenseDate = 'expense_date';
  static const paidBy = 'paid_by';
  static const notes = 'notes';

  static const checkpointSettlementId = 'settlement_id';
  static const checkpointPeriodEnd = 'period_end';
  static const checkpointSnapshotCreatedAt = 'snapshot_created_at';
  static const checkpointClosingBalance = 'closing_driver_balance';

  static const parameterCompanyId = 'p_company_id';
  static const parameterDriverId = 'p_driver_id';
  static const parameterBeforeExclusive = 'p_before_exclusive';
}

abstract final class DriverFinanceDbValues {
  static const movementAdvance = 'advance';
  static const movementDriverCharge = 'driver_charge';
  static const movementCashReturn = 'cash_return';
  static const paidByDriverAdvance = 'driver_advance';
  static const paidByDriverCash = 'driver_cash';
}
