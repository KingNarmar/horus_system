abstract final class DriverSettlementsDbTables {
  static const driverSettlements = 'driver_settlements';
  static const driverSettlementItems = 'driver_settlement_items';
  static const driverFinancialMovements = 'driver_financial_movements';
  static const drivers = 'drivers';
  static const trips = 'trips';
  static const expenseLedgerEntries = 'expense_ledger_entries';
}

abstract final class DriverSettlementsDbFields {
  static const driverId = 'driver_id';
  static const settlementId = 'settlement_id';
  static const periodStart = 'period_start';
  static const periodEnd = 'period_end';
  static const compensationRevisionId = 'compensation_revision_id';
  static const currencyCode = 'currency_code';
  static const currencyFractionDigits = 'currency_fraction_digits';

  static const openingDriverBalance = 'opening_driver_balance';
  static const openingDriverBalanceMinorUnits =
      'opening_driver_balance_minor_units';
  static const advancesTotal = 'advances_total';
  static const advancesTotalMinorUnits = 'advances_total_minor_units';
  static const driverPaidTripExpensesTotal = 'driver_paid_trip_expenses_total';
  static const driverPaidTripExpensesTotalMinorUnits =
      'driver_paid_trip_expenses_total_minor_units';
  static const returnedCashTotal = 'returned_cash_total';
  static const returnedCashTotalMinorUnits = 'returned_cash_total_minor_units';
  static const deductionsTotal = 'deductions_total';
  static const deductionsTotalMinorUnits = 'deductions_total_minor_units';
  static const settlementDeductionsTotal = 'settlement_deductions_total';
  static const settlementDeductionsTotalMinorUnits =
      'settlement_deductions_total_minor_units';
  static const grossSalary = 'gross_salary';
  static const grossSalaryMinorUnits = 'gross_salary_minor_units';
  static const salaryDeductionsTotal = 'salary_deductions_total';
  static const salaryDeductionsTotalMinorUnits =
      'salary_deductions_total_minor_units';
  static const balanceDeductionApplied = 'balance_deduction_applied';
  static const balanceDeductionAppliedMinorUnits =
      'balance_deduction_applied_minor_units';
  static const netSalaryPayable = 'net_salary_payable';
  static const netSalaryPayableMinorUnits = 'net_salary_payable_minor_units';
  static const closingDriverBalance = 'closing_driver_balance';
  static const closingDriverBalanceMinorUnits =
      'closing_driver_balance_minor_units';

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
  static const amountMinorUnits = 'amount_minor_units';
  static const labelKey = 'label_key';
  static const descriptionKey = 'description_key';
  static const metadata = 'metadata';

  static const fullName = 'full_name';
  static const isActive = 'is_active';
  static const tripId = 'trip_id';
  static const movementType = 'movement_type';
  static const movementDate = 'movement_date';
  static const expenseDate = 'expense_date';
  static const fundingSource = 'funding_source';
  static const description = 'description';
  static const isVoided = 'is_voided';
  static const originKind = 'origin_kind';
  static const originId = 'origin_id';
  static const paidBy = 'paid_by';
}
