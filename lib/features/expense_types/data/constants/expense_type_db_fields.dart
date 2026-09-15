abstract final class ExpenseTypeDbFields {
  static const tableName = 'expense_types';
  static const name = 'name';
  static const code = 'code';
  static const ledgerEligible = 'ledger_eligible';

  static const allColumns =
      'id, company_id, name, code, is_active, ledger_eligible, created_by, '
      'updated_by, created_at, updated_at';
}
