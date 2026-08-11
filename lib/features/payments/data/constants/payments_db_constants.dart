abstract final class PaymentsDbConstants {
  static const table = 'payments';

  static const invoiceId = 'invoice_id';
  static const customerId = 'customer_id';
  static const paymentMethodId = 'payment_method_id';
  static const paymentDate = 'payment_date';
  static const amountMinorUnits = 'amount_minor_units';
  static const currencyCode = 'currency_code';
  static const referenceNumber = 'reference_number';
  static const notes = 'notes';
  static const createdBy = 'created_by';

  static const registerPaymentRpc = 'register_payment';
  static const companyIdParam = 'p_company_id';
  static const invoiceIdParam = 'p_invoice_id';
  static const paymentMethodIdParam = 'p_payment_method_id';
  static const paymentDateParam = 'p_payment_date';
  static const amountMinorUnitsParam = 'p_amount_minor_units';
  static const currencyCodeParam = 'p_currency_code';
  static const referenceNumberParam = 'p_reference_number';
  static const notesParam = 'p_notes';
}

abstract final class PaymentsRpcErrorCodes {
  static const permissionDenied = 'P2710';
  static const invoiceNotFound = 'P2711';
  static const invoiceStatusInvalid = 'P2712';
  static const amountNotPositive = 'P2713';
  static const currencyMismatch = 'P2714';
  static const paymentMethodNotFound = 'P2715';
  static const paymentMethodInactive = 'P2716';
  static const paymentDateRequired = 'P2717';
  static const paymentDateBeforeInvoice = 'P2718';
  static const paymentDateFuture = 'P2719';
  static const overpayment = 'P2720';
  static const invoiceBalanceInvalid = 'P2721';
  static const invoiceLinesRequired = 'P2722';
  static const tripStateInvalid = 'P2723';
  static const companyNotFound = 'P2724';
  static const regionalSettingsNotConfigured = 'P2725';
  static const paymentMethodRequired = 'P2726';
  static const currencyRequired = 'P2727';
}
