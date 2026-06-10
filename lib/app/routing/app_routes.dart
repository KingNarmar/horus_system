abstract final class AppRoutes {
  static const String root = '/';

  static const String login = '/login';
  static const String register = '/register';

  static const String companyOnboarding = '/company/onboarding';
  static const String companyUsers = '/company/users';

  static const String appShell = '/app';
  static const String dashboard = '/app/dashboard';
  static const String customers = '/app/customers';
  static const String drivers = '/app/drivers';
  static const String fleet = '/app/fleet';
  static const String routes = '/app/routes';
  static const String trips = '/app/trips';
  static const String expenses = '/app/expenses';
  static const String invoices = '/app/invoices';
  static const String reports = '/app/reports';
  static const String settings = '/app/settings';

  static const Set<String> publicRoutes = {login, register};

  static const Set<String> authenticatedRoutes = {companyOnboarding};

  static const Set<String> companyRequiredRoutes = {
    appShell,
    dashboard,
    customers,
    drivers,
    fleet,
    routes,
    trips,
    expenses,
    invoices,
    reports,
    settings,
    companyUsers,
  };
}
