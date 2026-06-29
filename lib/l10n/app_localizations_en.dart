// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'H.O.R.U.S System';

  @override
  String get appSubtitle => 'Heavy Operations & Route Unified System';

  @override
  String get launchDescription =>
      'SaaS platform for heavy transport operations.';

  @override
  String get architectureBadge =>
      'Clean Architecture by the book • SOLID Principles';

  @override
  String get appShellDashboardLabel => 'Dashboard';

  @override
  String get appShellDashboardDescription =>
      'Live overview for company operations and finance.';

  @override
  String get appShellCustomersLabel => 'Customers';

  @override
  String get appShellCustomersDescription =>
      'Manage customer master data and account activity.';

  @override
  String get appShellDriversLabel => 'Drivers';

  @override
  String get appShellDriversDescription =>
      'Manage drivers, status, and driver actions.';

  @override
  String get appShellFleetLabel => 'Fleet';

  @override
  String get appShellFleetDescription =>
      'Manage tractor heads, trailers, and availability.';

  @override
  String get appShellRoutesLabel => 'Routes';

  @override
  String get appShellRoutesDescription =>
      'Manage loading points, delivery points, and lanes.';

  @override
  String get appShellTripsLabel => 'Trips';

  @override
  String get appShellTripsDescription => 'Create, track, and update trips.';

  @override
  String get appShellExpensesLabel => 'Expenses';

  @override
  String get appShellExpensesDescription =>
      'Track trip costs, fees, and financial movements.';

  @override
  String get appShellInvoicesLabel => 'Invoices';

  @override
  String get appShellInvoicesDescription =>
      'Create invoices, register payments, and track balances.';

  @override
  String get appShellReportsLabel => 'Reports';

  @override
  String get appShellReportsDescription =>
      'Review operational and financial reports.';

  @override
  String get appShellSettingsLabel => 'Settings';

  @override
  String get appShellSettingsDescription =>
      'Manage company settings, users, roles, and access.';

  @override
  String get appShellMoreLabel => 'More';

  @override
  String get logout => 'Logout';

  @override
  String companyWithName(String companyName) {
    return 'Company: $companyName';
  }

  @override
  String roleWithName(String roleName) {
    return 'Role: $roleName';
  }

  @override
  String get manageUsers => 'Manage users';

  @override
  String get companySettingsTitle => 'Company settings';

  @override
  String get noPermissionManageUsers =>
      'You do not have permission to manage users.';

  @override
  String get switchToArabic => 'Arabic';

  @override
  String get switchToEnglish => 'English';

  @override
  String get adaptiveAccessNotice =>
      'Same modules on every device. The screen layout changes, not the available actions.';

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

  @override
  String get loginWelcomeTitle => 'Welcome to H.O.R.U.S System';

  @override
  String get loginSubtitle =>
      'Sign in to continue managing heavy transport operations.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get emailRequired => 'Email is required.';

  @override
  String get passwordRequired => 'Password is required.';

  @override
  String get loginButton => 'Login';

  @override
  String get createNewAccountButton => 'Create a new account';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get registerTitle => 'Create your H.O.R.U.S account';

  @override
  String get registerSubtitle =>
      'Full name and phone are required for company user management.';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get fullNameRequired => 'Full name is required.';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneNumberRequired => 'Phone number is required.';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters.';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get checkYourEmailTitle => 'Check your email';

  @override
  String emailConfirmationMessage(String email) {
    return 'We sent a confirmation link to $email. Open the email, confirm your account, then return to H.O.R.U.S System and log in.';
  }

  @override
  String get backToLoginButton => 'Back to login';

  @override
  String get createCompanyTitle => 'Create company';

  @override
  String get createCompanyFormTitle => 'Create your company';

  @override
  String get createCompanySubtitle =>
      'Set up the first company workspace for H.O.R.U.S System.';

  @override
  String get companyNameLabel => 'Company name';

  @override
  String get companyNameRequired => 'Company name is required.';

  @override
  String get businessTypeLabel => 'Business type';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get countryLabel => 'Country';

  @override
  String get cityLabel => 'City';

  @override
  String get createCompanyButton => 'Create company';

  @override
  String get companyContextLoadedTitle => 'Company context loaded';

  @override
  String get companyContextNextStep =>
      'Next step: current company context and app shell.';

  @override
  String get currentCompanyContextRequired =>
      'Current company context is required.';

  @override
  String get companyUsersTitle => 'Company Users';

  @override
  String get inviteButton => 'Invite';

  @override
  String get noCompanyUsersFound => 'No company users found.';

  @override
  String get inviteFlowComingSoon =>
      'Invite flow will be implemented in a later issue.';

  @override
  String get activeStatus => 'Active';

  @override
  String get inactiveStatus => 'Inactive';

  @override
  String roleLine(String roleName) {
    return 'Role: $roleName';
  }

  @override
  String statusLine(String status) {
    return 'Status: $status';
  }

  @override
  String get incompleteProfileMessage =>
      'Profile is incomplete. Ask this user to complete their profile.';

  @override
  String get customersTitle => 'Customers';

  @override
  String get addCustomerButton => 'Add customer';

  @override
  String get addCustomerTitle => 'Add customer';

  @override
  String get editCustomerTitle => 'Edit customer';

  @override
  String get editCustomerButton => 'Edit';

  @override
  String get deactivateCustomerButton => 'Deactivate';

  @override
  String get reactivateCustomerButton => 'Reactivate';

  @override
  String get searchCustomersHint =>
      'Search customers by name, contact, phone, email, city, country, or TRN';

  @override
  String get customersStatusAllFilter => 'All';

  @override
  String get customersStatusActiveFilter => 'Active';

  @override
  String get customersStatusInactiveFilter => 'Inactive';

  @override
  String get customerNameLabel => 'Customer name';

  @override
  String get customerNameRequired => 'Customer name is required.';

  @override
  String get contactPersonLabel => 'Contact person';

  @override
  String get taxRegistrationNumberLabel => 'TRN / Tax number';

  @override
  String get addressLabel => 'Address';

  @override
  String get creditLimitLabel => 'Credit limit';

  @override
  String get creditLimitInvalid =>
      'Credit limit must be a valid non-negative number.';

  @override
  String get saveButton => 'Save';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get retryButton => 'Retry';

  @override
  String get noCustomersFound => 'No customers found.';

  @override
  String get noCustomersMatchFilters =>
      'No customers match the current search or status filter.';

  @override
  String get customerNameHeader => 'Customer';

  @override
  String get contactHeader => 'Contact';

  @override
  String get statusHeader => 'Status';

  @override
  String get actionsHeader => 'Actions';

  @override
  String contactPersonLine(String contactPerson) {
    return 'Contact: $contactPerson';
  }

  @override
  String phoneLine(String phone) {
    return 'Phone: $phone';
  }

  @override
  String emailLine(String email) {
    return 'Email: $email';
  }

  @override
  String cityLine(String city) {
    return 'City: $city';
  }

  @override
  String auditTimelineHeader(String actorName, String role, String dateTime) {
    return '$actorName • $role • $dateTime';
  }

  @override
  String auditChangeLine(String field, String oldValue, String newValue) {
    return '$field: $oldValue → $newValue';
  }

  @override
  String get driverFinanceTitle => 'Driver finance';

  @override
  String get driverBalancePlaceholderDescription =>
      'Initial balance calculated from recorded advances and deductions. Monthly settlement will be implemented later.';

  @override
  String get addDriverAdvanceButton => 'Add advance';

  @override
  String get addDriverDeductionButton => 'Add deduction';

  @override
  String get addDriverAdvanceTitle => 'Add driver advance';

  @override
  String get addDriverDeductionTitle => 'Add driver deduction';

  @override
  String get driverMovementAmountLabel => 'Amount';

  @override
  String get driverMovementDateLabel => 'Date';

  @override
  String get driverMovementTripPickerComingSoon =>
      'Trip selection will be added later. This deduction will be saved as a general deduction for now.';

  @override
  String get driverMovementNotesLabel => 'Notes';

  @override
  String get totalAdvancesLabel => 'Total advances';

  @override
  String get totalDeductionsLabel => 'Total deductions';

  @override
  String get netDriverBalanceLabel => 'Current balance';

  @override
  String get noDriverFinancialMovements => 'No financial movements yet.';

  @override
  String get loadingDriverFinancialMovements =>
      'Loading driver financial movements...';

  @override
  String get savingDriverFinancialMovement => 'Saving...';

  @override
  String get invalidDriverMovementAmount =>
      'Enter a valid amount greater than zero.';

  @override
  String get driverMovementTripLine => 'Trip';

  @override
  String get driverMovementTypeAdvance => 'Advance';

  @override
  String get driverMovementTypeDeduction => 'Deduction';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String get profileDetailsNotSetYet => 'Profile details not set yet';
}
