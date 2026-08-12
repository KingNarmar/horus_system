abstract final class CustomerStatementsDbConstants {
  static const getStatementSourceRpc = 'get_customer_statement_source';

  static const companyIdParam = 'p_company_id';
  static const customerIdParam = 'p_customer_id';
  static const fromDateParam = 'p_from_date';
  static const toDateParam = 'p_to_date';

  static const company = 'company';
  static const customer = 'customer';
  static const period = 'period';
  static const opening = 'opening';
  static const movements = 'movements';

  static const companyId = 'company_id';
  static const baseCurrencyCode = 'base_currency_code';
  static const baseCurrencyFractionDigits = 'base_currency_fraction_digits';
  static const businessTimezone = 'business_timezone';

  static const customerId = 'customer_id';
  static const customerName = 'customer_name';
  static const isActive = 'is_active';

  static const fromDate = 'from_date';
  static const toDate = 'to_date';

  static const invoices = 'invoices';
  static const payments = 'payments';
  static const currencyCode = 'currency_code';
  static const totalMinorUnits = 'total_minor_units';

  static const sourceType = 'source_type';
  static const sourceId = 'source_id';
  static const businessDate = 'business_date';
  static const eventTimestamp = 'event_timestamp';
  static const amountMinorUnits = 'amount_minor_units';
  static const reference = 'reference';
  static const relatedInvoiceId = 'related_invoice_id';
}

abstract final class CustomerStatementsRpcErrorCodes {
  static const permissionDenied = 'P2810';
  static const invalidDateRange = 'P2811';
  static const companyNotFound = 'P2812';
  static const regionalSettingsNotConfigured = 'P2813';
  static const customerNotFound = 'P2814';
}
