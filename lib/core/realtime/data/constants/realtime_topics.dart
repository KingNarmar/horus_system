abstract final class RealtimeTopics {
  static const customersChangedEvent = 'changed';
  static const customersResource = 'customers';
  static const driversResource = 'drivers';
  static const fleetResource = 'fleet';
  static const routesResource = 'routes';
  static const tripsResource = 'trips';
  static const tripDocumentsResource = 'trip_documents';
  static const driverFinanceResource = 'driver_finance';
  static const driverSettlementsResource = 'driver_settlements';
  static const expenseLedgerResource = 'expense_ledger';
  static const companyExpensesResource = 'company_expenses';
  static const tripExpensesResource = 'trip_expenses';
  static const fleetLicenseDocumentsResource = 'fleet_license_documents';

  static String customers(String companyId) =>
      'horus:company:$companyId:customers';

  static String drivers(String companyId) => 'horus:company:$companyId:drivers';

  static String routes(String companyId) => 'horus:company:$companyId:routes';

  static String trips(String companyId) => 'horus:company:$companyId:trips';

  static String companyExpenses(String companyId) =>
      'horus:company:$companyId:company_expenses';

  static String driverFinance(String companyId) =>
      'horus:company:$companyId:driver_finance';

  static String driverSettlements(String companyId) =>
      'horus:company:$companyId:driver_settlements';

  static String expenseLedger(String companyId) =>
      'horus:company:$companyId:expense_ledger';

  static String tripExpenses(String companyId) =>
      'horus:company:$companyId:trip_expenses';

  static String tripDocuments(String companyId) =>
      'horus:company:$companyId:trip_documents';

  static String fleet(String companyId) => 'horus:company:$companyId:fleet';

  static String fleetLicenseDocuments(String companyId) =>
      'horus:company:$companyId:fleet_license_documents';
}
