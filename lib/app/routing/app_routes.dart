abstract final class AppRoutes {
  static const String root = '/';

  static const String login = '/login';
  static const String register = '/register';

  static const String companyCreation = '/company/create';
  static const String companyUsers = '/company/users';
  static const String companyInvitation = '/company/invitation';

  static const String appShell = '/app';
  static const String dashboard = '/app/dashboard';
  static const String customers = '/app/customers';
  static const String drivers = '/app/drivers';
  static const String fleet = '/app/fleet';
  static const String routes = '/app/routes';
  static const String trips = '/app/trips';
  static const String expenses = '/app/expenses';
  static const String driverSettlements = '/app/driver-settlements';
  static const String invoices = '/app/invoices';
  static const String payments = '/app/payments';
  static const String customerStatements = '/app/customer-statements';
  static const String reports = '/app/reports';
  static const String settings = '/app/settings';

  static const Set<String> publicRoutes = {login, register, companyInvitation};

  static const Set<String> authenticatedRoutes = {companyCreation};

  static const Set<String> companyRequiredRoutes = {
    appShell,
    dashboard,
    customers,
    drivers,
    fleet,
    routes,
    trips,
    expenses,
    driverSettlements,
    invoices,
    payments,
    customerStatements,
    reports,
    settings,
    companyUsers,
  };
}
