abstract final class PaymentFailureCodes {
  static const permissionView = 'permission_payments_view';
  static const permissionManage = 'permission_payments_management';

  static const validationInvoiceIdRequired =
      'validation_payment_invoice_id_required';
  static const validationPaymentMethodIdRequired =
      'validation_payment_method_id_required';
  static const validationAmountInvalid = 'validation_payment_amount_invalid';
  static const validationAmountPositive = 'validation_payment_amount_positive';
  static const validationCurrencyInvalid =
      'validation_payment_currency_invalid';
  static const validationCurrencyMismatch =
      'validation_payment_currency_mismatch';
  static const validationDateRequired = 'validation_payment_date_required';
  static const validationDateBeforeInvoice =
      'validation_payment_date_before_invoice';
  static const validationDateFuture = 'validation_payment_date_future';

  static const invoiceNotFound = 'payment_invoice_not_found';
  static const paymentMethodNotFound = 'payment_method_not_found';

  static const conflictInvoiceStatusInvalid =
      'conflict_payment_invoice_status_invalid';
  static const conflictPaymentMethodInactive =
      'conflict_payment_method_inactive';
  static const conflictOverpayment = 'conflict_payment_overpayment';
  static const conflictInvoiceBalanceInvalid =
      'conflict_payment_invoice_balance_invalid';
  static const conflictInvoiceLinesRequired =
      'conflict_payment_invoice_lines_required';
  static const conflictTripStateInvalid = 'conflict_payment_trip_state_invalid';
}
