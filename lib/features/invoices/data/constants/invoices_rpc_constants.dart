abstract final class InvoicesRpcConstants {
  static const getBillableTrips = 'get_billable_trips';
  static const getCreationContext = 'get_invoice_creation_context';
  static const createDraft = 'create_invoice_draft';
  static const updateDraft = 'update_invoice_draft';
  static const issue = 'issue_invoice';
  static const cancel = 'cancel_invoice';
  static const updateSettings = 'update_company_invoice_settings';

  static const companyId = 'p_company_id';
  static const invoiceId = 'p_invoice_id';
  static const customerId = 'p_customer_id';
  static const tripIds = 'p_trip_ids';
  static const discountMinorUnits = 'p_discount_minor_units';
  static const taxRateBasisPoints = 'p_tax_rate_basis_points';
  static const issueDate = 'p_issue_date';
  static const dueDate = 'p_due_date';
  static const notes = 'p_notes';
  static const reason = 'p_reason';
  static const invoicePrefix = 'p_invoice_prefix';
}
