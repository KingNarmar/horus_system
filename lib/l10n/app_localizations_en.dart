import 'app_localizations.dart';

// ignore_for_file: type=lint

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'H.O.R.U.S System';

  @override
  String get appSubtitle => 'Heavy Operations & Route Unified System';

  @override
  String get launchDescription => 'SaaS platform for heavy transport operations.';

  @override
  String get architectureBadge => 'Clean Architecture by the book • SOLID Principles';

  @override
  String get appShellDashboardLabel => 'Dashboard';

  @override
  String get appShellDashboardDescription => 'Live overview for company operations and finance.';

  @override
  String get appShellCustomersLabel => 'Customers';

  @override
  String get appShellCustomersDescription => 'Manage customer master data and account activity.';

  @override
  String get appShellDriversLabel => 'Drivers';

  @override
  String get appShellDriversDescription => 'Manage drivers, status, and driver actions.';

  @override
  String get appShellFleetLabel => 'Fleet';

  @override
  String get appShellFleetDescription => 'Manage tractor heads, trailers, and availability.';

  @override
  String get appShellRoutesLabel => 'Routes';

  @override
  String get appShellRoutesDescription => 'Manage loading points, delivery points, and lanes.';

  @override
  String get appShellTripsLabel => 'Trips';

  @override
  String get appShellTripsDescription => 'Create, track, and update trips.';

  @override
  String get appShellExpensesLabel => 'Expenses';

  @override
  String get appShellExpensesDescription => 'Track trip costs, fees, and financial movements.';

  @override
  String get appShellInvoicesLabel => 'Invoices';

  @override
  String get appShellInvoicesDescription => 'Create invoices, register payments, and track balances.';

  @override
  String get appShellReportsLabel => 'Reports';

  @override
  String get appShellReportsDescription => 'Review operational and financial reports.';

  @override
  String get appShellSettingsLabel => 'Settings';

  @override
  String get appShellSettingsDescription => 'Manage company settings, users, roles, and access.';

  @override
  String get appShellMoreLabel => 'More';

  @override
  String get logout => 'Logout';

  @override
  String companyWithName(String companyName) => 'Company: $companyName';

  @override
  String roleWithName(String roleName) => 'Role: $roleName';

  @override
  String get companySettingsTitle => 'Company settings';

  @override
  String get manageUsers => 'Manage users';

  @override
  String get noPermissionManageUsers => 'You do not have permission to manage users.';

  @override
  String get switchToArabic => 'Arabic';

  @override
  String get switchToEnglish => 'English';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleOperations => 'Operations';

  @override
  String get roleAccountant => 'Accountant';

  @override
  String get roleViewer => 'Viewer';

  @override
  String get roleDriver => 'Driver';
}
