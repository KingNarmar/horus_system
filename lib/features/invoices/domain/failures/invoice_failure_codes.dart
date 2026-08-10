abstract final class InvoiceFailureCodes {
  static const permissionSettingsManagement =
      'permission_invoice_settings_management';
  static const validationPrefixInvalid = 'validation_invoice_prefix_invalid';
  static const validationFreightPrecisionInvalid =
      'validation_invoice_freight_precision_invalid';
  static const validationIssueDateRequired =
      'validation_invoice_issue_date_required';
  static const validationDueDateRequired =
      'validation_invoice_due_date_required';
  static const conflictSettingsNotConfigured =
      'conflict_invoice_settings_not_configured';
  static const conflictSequenceExhausted =
      'conflict_invoice_sequence_exhausted';
  static const conflictHasPayments = 'conflict_invoice_has_payments';
  static const notFound = 'invoice_not_found';
  static const customerNotFound = 'invoice_customer_not_found';
}
