abstract final class DriverSettlementsDbTables {
  static const driverSettlements = 'driver_settlements';
  static const driverSettlementItems = 'driver_settlement_items';
  static const driverFinancialMovements = 'driver_financial_movements';
  static const trips = 'trips';
  static const tripExpenses = 'trip_expenses';
}

abstract final class DriverSettlementsDbFields {
  static const driverId = 'driver_id';
  static const settlementId = 'settlement_id';
  static const periodStart = 'period_start';
  static const periodEnd = 'period_end';
  static const openingDriverBalance = 'opening_driver_balance';
  static const advancesTotal = 'advances_total';
  static const driverPaidTripExpensesTotal =
      'driver_paid_trip_expenses_total';
  static const returnedCashTotal = 'returned_cash_total';
  static const deductionsTotal = 'deductions_total';
  static const settlementDeductionsTotal = 'settlement_deductions_total';
  static const grossSalary = 'gross_salary';
  static const salaryDeductionsTotal = 'salary_deductions_total';
  static const balanceDeductionApplied = 'balance_deduction_applied';
  static const netSalaryPayable = 'net_salary_payable';
  static const closingDriverBalance = 'closing_driver_balance';
  static const status = 'status';
  static const notes = 'notes';
  static const finalizedAt = 'finalized_at';
  static const finalizedBy = 'finalized_by';
  static const voidedAt = 'voided_at';
  static const voidedBy = 'voided_by';
  static const voidReason = 'void_reason';
  static const createdBy = 'created_by';
  static const updatedBy = 'updated_by';

  static const sourceType = 'source_type';
  static const sourceId = 'source_id';
  static const sourceDate = 'source_date';
  static const direction = 'direction';
  static const amount = 'amount';
  static const labelKey = 'label_key';
  static const descriptionKey = 'description_key';
  static const metadata = 'metadata';

  static const tripId = 'trip_id';
  static const movementType = 'movement_type';
  static const movementDate = 'movement_date';
  static const expenseName = 'expense_name';
  static const expenseDate = 'expense_date';
  static const paidBy = 'paid_by';
}

abstract final class DriverSettlementAuditKeys {
  static const entityDisplayName = 'driver_settlement';
  static const created = 'driver_settlement_created';
  static const finalized = 'driver_settlement_finalized';
  static const voided = 'driver_settlement_voided';
}
