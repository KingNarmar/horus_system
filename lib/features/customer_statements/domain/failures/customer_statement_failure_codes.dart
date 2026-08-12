abstract final class CustomerStatementFailureCodes {
  static const permissionView = 'permission_customer_statements_view';

  static const validationCustomerIdRequired =
      'validation_customer_statement_customer_id_required';
  static const validationDateRange =
      'validation_customer_statement_date_range';

  static const customerNotFound = 'customer_statement_customer_not_found';

  static const conflictSourceInvalid =
      'conflict_customer_statement_source_invalid';
  static const conflictCurrencyMismatch =
      'conflict_customer_statement_currency_mismatch';
  static const conflictMovementInvalid =
      'conflict_customer_statement_movement_invalid';
}
