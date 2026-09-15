abstract final class ExpenseLedgerFailureCodes {
  static const permissionView = 'expense_ledger_permission_view';
  static const permissionManage = 'expense_ledger_permission_manage';
  static const validationExpenseTypeRequired =
      'expense_ledger_expense_type_required';
  static const validationAmountInvalid = 'expense_ledger_amount_invalid';
  static const validationAttributionInvalid =
      'expense_ledger_attribution_invalid';
  static const validationFundingSourceInvalid =
      'expense_ledger_funding_source_invalid';
  static const financialConfigurationRequired =
      'expense_ledger_financial_configuration_required';
  static const currencyMismatch = 'expense_ledger_currency_mismatch';
  static const expenseTypeUnavailable = 'expense_ledger_expense_type_unavailable';
  static const notFound = 'expense_ledger_not_found';
  static const conflictAlreadyVoided = 'expense_ledger_already_voided';
  static const serverError = 'expense_ledger_server_error';
  static const unexpectedError = 'expense_ledger_unexpected_error';
}
