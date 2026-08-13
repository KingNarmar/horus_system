abstract final class DashboardDbConstants {
  static const getDashboardSourceRpc = 'get_dashboard_source';
  static const companyIdParam = 'p_company_id';

  static const company = 'company';
  static const metrics = 'metrics';
  static const financial = 'financial';
  static const validation = 'validation';

  static const companyId = 'company_id';
  static const baseCurrencyCode = 'base_currency_code';
  static const baseCurrencyFractionDigits = 'base_currency_fraction_digits';
  static const businessTimezone = 'business_timezone';
  static const businessDate = 'business_date';

  static const todayTrips = 'today_trips';
  static const runningTrips = 'running_trips';
  static const deliveredTrips = 'delivered_trips';
  static const availableVehicles = 'available_vehicles';
  static const vehiclesOnTrip = 'vehicles_on_trip';
  static const unpaidInvoices = 'unpaid_invoices';

  static const revenueMinorUnits = 'revenue_minor_units';
  static const tripExpensesMinorUnits = 'trip_expenses_minor_units';
  static const companyExpensesMinorUnits = 'company_expenses_minor_units';

  static const financialCurrencyMismatchCount =
      'financial_currency_mismatch_count';
  static const expensePrecisionLossCount = 'expense_precision_loss_count';
  static const negativeExpenseCount = 'negative_expense_count';
  static const invalidInvoiceBalanceCount = 'invalid_invoice_balance_count';
}

abstract final class DashboardRpcErrorCodes {
  static const permissionDenied = 'P2910';
  static const companyNotFound = 'P2911';
  static const regionalSettingsNotConfigured = 'P2912';
}
