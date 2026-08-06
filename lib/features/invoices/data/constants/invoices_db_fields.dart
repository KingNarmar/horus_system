abstract final class InvoicesDbFields {
  static const invoicesTable = 'invoices';
  static const invoiceLinesTable = 'invoice_lines';
  static const invoiceSequencesTable = 'invoice_sequences';
  static const companyInvoiceSettingsTable = 'company_invoice_settings';

  static const customerId = 'customer_id';
  static const status = 'status';
  static const invoiceNumber = 'invoice_number';
  static const currencyCode = 'currency_code';

  static const customerName = 'customer_name';
  static const customerTaxRegistrationNumber =
      'customer_tax_registration_number';
  static const customerAddress = 'customer_address';
  static const customerCity = 'customer_city';
  static const customerCountry = 'customer_country';

  static const subtotalMinorUnits = 'subtotal_minor_units';
  static const discountMinorUnits = 'discount_minor_units';
  static const taxableMinorUnits = 'taxable_minor_units';
  static const taxRateBasisPoints = 'tax_rate_basis_points';
  static const taxMinorUnits = 'tax_minor_units';
  static const totalMinorUnits = 'total_minor_units';

  static const issueDate = 'issue_date';
  static const dueDate = 'due_date';
  static const notes = 'notes';
  static const cancellationReason = 'cancellation_reason';
  static const issuedAt = 'issued_at';
  static const issuedBy = 'issued_by';
  static const cancelledAt = 'cancelled_at';
  static const cancelledBy = 'cancelled_by';

  static const invoiceId = 'invoice_id';
  static const tripId = 'trip_id';
  static const linePosition = 'line_position';
  static const loadingOrderNumber = 'loading_order_number';
  static const waybillNumber = 'waybill_number';
  static const serviceDate = 'service_date';
  static const quantityTons = 'quantity_tons';
  static const amountMinorUnits = 'amount_minor_units';

  static const linesRelation = 'invoice_lines';

  static const invoicePrefix = 'invoice_prefix';
  static const invoiceYear = 'invoice_year';
  static const lastValue = 'last_value';

  static const isCustomerActive = 'is_customer_active';
  static const isAlreadyInvoiced = 'is_already_invoiced';
  static const freightMinorUnits = 'freight_minor_units';
  static const trips = 'trips';
  static const customer = 'customer';
}
