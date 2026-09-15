abstract final class ExpenseLedgerDbFields {
  static const tableName = 'expense_ledger_entries';

  static const id = 'id';
  static const companyId = 'company_id';
  static const expenseTypeId = 'expense_type_id';
  static const amountMinorUnits = 'amount_minor_units';
  static const currencyCode = 'currency_code';
  static const currencyFractionDigits = 'currency_fraction_digits';
  static const expenseDate = 'expense_date';
  static const fundingSource = 'funding_source';
  static const tripId = 'trip_id';
  static const driverId = 'driver_id';
  static const tractorHeadId = 'tractor_head_id';
  static const trailerId = 'trailer_id';
  static const referenceNumber = 'reference_number';
  static const notes = 'notes';
  static const isVoided = 'is_voided';
  static const voidedAt = 'voided_at';
  static const voidedBy = 'voided_by';
  static const voidReason = 'void_reason';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';

  static const allColumns =
      'id, company_id, expense_type_id, amount_minor_units, currency_code, '
      'currency_fraction_digits, expense_date, funding_source, trip_id, '
      'driver_id, tractor_head_id, trailer_id, reference_number, notes, '
      'is_voided, voided_at, voided_by, void_reason, created_at, updated_at';
}
