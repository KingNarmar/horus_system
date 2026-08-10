abstract final class PaymentMethodDbFields {
  static const tableName = 'payment_methods';

  static const name = 'name';
  static const code = 'code';

  static const allColumns =
      'id, company_id, name, code, is_active, created_by, updated_by, created_at, updated_at';
}
