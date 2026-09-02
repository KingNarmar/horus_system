abstract final class ExpenseTypeDbFields {
  static const tableName = 'expense_types';
  static const name = 'name';

  static const allColumns =
      'id, company_id, name, is_active, created_by, updated_by, created_at, updated_at';
}
