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
  String get failureAuthInvalidCredentials => 'Incorrect email or password.';

  @override
  String get failureAuthEmailNotConfirmed =>
      'Confirm your email before signing in.';

  @override
  String get failureAuthAccountAlreadyExists =>
      'An account already exists for this email.';

  @override
  String get failureAuthWeakPassword =>
      'The password does not meet the security requirements.';

  @override
  String get failureAuthInvalidEmail => 'Enter a valid email address.';

  @override
  String get failureAuthRateLimited => 'Too many attempts. Try again later.';

  @override
  String get failureAuthError =>
      'We couldn\'t complete this account action. Try again.';

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
  String get okButton => 'OK';

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
  String get customerViewDetails => 'Details';

  @override
  String get customerBasicInfo => 'Basic information';

  @override
  String get customerAccountability => 'Accountability';

  @override
  String get customerActivityTimeline => 'Activity timeline';

  @override
  String get customerCreatedBy => 'Created by';

  @override
  String get customerCreatedRole => 'Created role';

  @override
  String get customerCreatedAt => 'Created at';

  @override
  String get customerLastActivityBy => 'Last activity by';

  @override
  String get customerLastActivityRole => 'Last activity role';

  @override
  String get customerLastActivityAt => 'Last activity at';

  @override
  String get customerLoadingActivity => 'Loading activity...';

  @override
  String get customerNoActivityFound => 'No activity found for this customer.';

  @override
  String get customerChanges => 'Changes';

  @override
  String get customerEmptyValue => 'Empty';

  @override
  String get customerUnknownUser => 'Unknown user';

  @override
  String get customerNotAvailable => 'Not available';

  @override
  String get customerConfirmDeactivateTitle => 'Confirm deactivation';

  @override
  String get customerConfirmReactivateTitle => 'Confirm reactivation';

  @override
  String get customerConfirmDeactivateMessage =>
      'Do you want to deactivate this customer?';

  @override
  String get customerConfirmReactivateMessage =>
      'Do you want to reactivate this customer?';

  @override
  String get customerSearchHintShort => 'Search customers';

  @override
  String customerDetailsTitle(String name) {
    return 'Customer details: $name';
  }

  @override
  String get customerAuditActionCreated => 'Created';

  @override
  String get customerAuditActionUpdated => 'Updated';

  @override
  String get customerAuditActionDeactivated => 'Deactivated';

  @override
  String get customerAuditActionReactivated => 'Reactivated';

  @override
  String get customerAuditActionStatusChanged => 'Status changed';

  @override
  String get driversTitle => 'Drivers';

  @override
  String get addDriverButton => 'Add driver';

  @override
  String get editDriverButton => 'Edit';

  @override
  String get deactivateDriverButton => 'Deactivate';

  @override
  String get reactivateDriverButton => 'Reactivate';

  @override
  String get viewDriverDetails => 'View details';

  @override
  String get driverDetails => 'Driver details';

  @override
  String get searchDriversHint =>
      'Search by name, phone, national ID, or license';

  @override
  String get driversStatusAllFilter => 'All';

  @override
  String get driversStatusActiveFilter => 'Active';

  @override
  String get driversStatusInactiveFilter => 'Inactive';

  @override
  String get noDriversFound => 'No drivers found.';

  @override
  String get noDriversMatchFilters =>
      'No drivers match the current search or status filter.';

  @override
  String get driverNameLabel => 'Driver name';

  @override
  String get driverNameRequired => 'Driver name is required.';

  @override
  String get nationalIdLabel => 'National ID';

  @override
  String get licenseNumberLabel => 'License number';

  @override
  String get licenseExpiryDateLabel => 'License expiry date';

  @override
  String get licenseExpiryDateMustBeFuture =>
      'License expiry date must be today or a future date.';

  @override
  String get driverImagesSectionTitle => 'Driver images';

  @override
  String get driverProfileImageLabel => 'Driver photo';

  @override
  String get driverLicenseImageLabel => 'License image';

  @override
  String get driverLicenseFrontImageLabel => 'License front image';

  @override
  String get driverLicenseBackImageLabel => 'License back image';

  @override
  String get driverNationalIdImageLabel => 'National ID image';

  @override
  String get driverNationalIdFrontImageLabel => 'National ID front image';

  @override
  String get driverNationalIdBackImageLabel => 'National ID back image';

  @override
  String get driverChooseImageFromFiles => 'Choose file';

  @override
  String get driverTakeImageWithCamera => 'Camera';

  @override
  String get driverImageAlreadyUploaded => 'Image uploaded';

  @override
  String get driverImageSelectionFailedTitle => 'Image selection failed';

  @override
  String get driverExistingImageValue => 'Existing image';

  @override
  String get driverUpdatedImageValue => 'Updated image';

  @override
  String get driverImagesLoading => 'Loading images...';

  @override
  String get notesLabel => 'Notes';

  @override
  String get driverBasicInfo => 'Basic information';

  @override
  String get driverAccountability => 'Accountability';

  @override
  String get driverActivityTimeline => 'Activity timeline';

  @override
  String get driverCreatedBy => 'Created by';

  @override
  String get driverCreatedRole => 'Created role';

  @override
  String get driverCreatedAt => 'Created at';

  @override
  String get driverLastActivityBy => 'Last activity by';

  @override
  String get driverLastActivityRole => 'Last activity role';

  @override
  String get driverLastActivityAt => 'Last activity at';

  @override
  String get driverLoadingActivity => 'Loading activity...';

  @override
  String get driverNoActivityFound => 'No activity yet.';

  @override
  String get driverUnknownUser => 'Unknown user';

  @override
  String get driverNotAvailable => 'Not available';

  @override
  String get driverConfirmDeactivateTitle => 'Confirm driver deactivation';

  @override
  String get driverConfirmReactivateTitle => 'Confirm driver reactivation';

  @override
  String get driverConfirmDeactivateMessage =>
      'Do you want to deactivate this driver?';

  @override
  String get driverConfirmReactivateMessage =>
      'Do you want to reactivate this driver?';

  @override
  String driverDetailsTitle(String name) {
    return 'Driver details: $name';
  }

  @override
  String get driverStatusActiveLabel => 'Active';

  @override
  String get driverStatusInactiveLabel => 'Inactive';

  @override
  String get driverAuditActionCreated => 'Created';

  @override
  String get driverAuditActionUpdated => 'Updated';

  @override
  String get driverAuditActionDeactivated => 'Deactivated';

  @override
  String get driverAuditActionReactivated => 'Reactivated';

  @override
  String get driverAuditActionFinanceAdded =>
      'Driver finance movement recorded';

  @override
  String get driverPhoneFieldLabel => 'Phone';

  @override
  String get driverStatusFieldLabel => 'Status';

  @override
  String auditTimelineHeader(String actorName, String role, String dateTime) {
    return '$actorName • $role • $dateTime';
  }

  @override
  String auditChangeLine(String field, String oldValue, String newValue) {
    return '$field: $oldValue → $newValue';
  }

  @override
  String get routesTitle => 'Routes';

  @override
  String get addRouteButton => 'Add route';

  @override
  String get addRouteTitle => 'Add route';

  @override
  String get editRouteTitle => 'Edit route';

  @override
  String get loadingLocationLabel => 'Loading location';

  @override
  String get unloadingLocationLabel => 'Unloading location';

  @override
  String get governorateFromLabel => 'Loading governorate';

  @override
  String get governorateToLabel => 'Unloading governorate';

  @override
  String get defaultFreightPriceLabel => 'Default freight price';

  @override
  String get routeNotesLabel => 'Notes';

  @override
  String get loadingLocationRequired => 'Loading location is required.';

  @override
  String get unloadingLocationRequired => 'Unloading location is required.';

  @override
  String get defaultFreightPriceInvalid => 'Enter a valid non-negative number.';

  @override
  String get searchRoutesHint => 'Search routes';

  @override
  String get routesStatusAllFilter => 'All';

  @override
  String get routesStatusActiveFilter => 'Active';

  @override
  String get routesStatusInactiveFilter => 'Inactive';

  @override
  String get noRoutesFound => 'No routes found.';

  @override
  String get noRoutesMatchFilters =>
      'No routes match the current search or filter.';

  @override
  String get routeDeactivateButton => 'Deactivate';

  @override
  String get routeReactivateButton => 'Reactivate';

  @override
  String get confirmRouteDeactivateTitle => 'Confirm route deactivation';

  @override
  String get confirmRouteReactivateTitle => 'Confirm route reactivation';

  @override
  String get confirmRouteDeactivateMessage =>
      'Do you want to deactivate this route?';

  @override
  String get confirmRouteReactivateMessage =>
      'Do you want to reactivate this route?';

  @override
  String get routeLoadingHeader => 'Loading';

  @override
  String get routeUnloadingHeader => 'Unloading';

  @override
  String get routeGovernoratesHeader => 'Governorates';

  @override
  String get routeDefaultPriceHeader => 'Default price';

  @override
  String get routeStatusHeader => 'Status';

  @override
  String get routeActiveStatusLabel => 'Active';

  @override
  String get routeInactiveStatusLabel => 'Inactive';

  @override
  String get routeEditButton => 'Edit';

  @override
  String get routeViewDetails => 'View details';

  @override
  String routeDetailsTitle(String name) {
    return 'Route details: $name';
  }

  @override
  String get routeBasicInfo => 'Basic information';

  @override
  String get routeAccountability => 'Accountability';

  @override
  String get routeCreatedBy => 'Created by';

  @override
  String get routeCreatedRole => 'Created role';

  @override
  String get routeCreatedAt => 'Created at';

  @override
  String get routeLastActivityBy => 'Last activity by';

  @override
  String get routeLastActivityRole => 'Last activity role';

  @override
  String get routeLastActivityAt => 'Last activity at';

  @override
  String get routeActivityTimeline => 'Activity timeline';

  @override
  String get routeLoadingActivity => 'Loading activity...';

  @override
  String get routeNoActivityFound => 'No activity yet.';

  @override
  String get routeChanges => 'Changes';

  @override
  String get routeUnknownUser => 'Unknown user';

  @override
  String get routeNotAvailable => 'N/A';

  @override
  String get routeAuditActionCreated => 'Created';

  @override
  String get routeAuditActionUpdated => 'Updated';

  @override
  String get routeAuditActionDeactivated => 'Deactivated';

  @override
  String get routeAuditActionReactivated => 'Reactivated';

  @override
  String get routeAuditActionStatusChanged => 'Status changed';

  @override
  String routeAuditTimelineHeader(String actor, String role, String dateTime) {
    return '$actor ($role) - $dateTime';
  }

  @override
  String routeAuditChangeLine(String label, String oldValue, String newValue) {
    return '$label: from $oldValue to $newValue';
  }

  @override
  String get fleetTitle => 'Fleet';

  @override
  String get tractorHeadsTab => 'Tractor heads';

  @override
  String get trailersTab => 'Trailers';

  @override
  String get addTractorHeadButton => 'Add tractor head';

  @override
  String get addTrailerButton => 'Add trailer';

  @override
  String get editTractorHeadTitle => 'Edit tractor head';

  @override
  String get editTrailerTitle => 'Edit trailer';

  @override
  String get plateNumberLabel => 'Plate number';

  @override
  String get plateNumberRequired => 'Plate number is required.';

  @override
  String get vehicleStatusLabel => 'Vehicle status';

  @override
  String get vehicleLicenseExpiryDateLabel => 'License expiry date';

  @override
  String get expectedFuelConsumptionLabel => 'Expected fuel consumption';

  @override
  String get expectedFuelConsumptionInvalid =>
      'Enter a valid non-negative number.';

  @override
  String get vehicleNotesLabel => 'Notes';

  @override
  String get technicalNotesLabel => 'Technical notes';

  @override
  String get searchFleetHint => 'Search by plate, status, or notes';

  @override
  String get fleetStatusAllFilter => 'All';

  @override
  String get fleetStatusActiveFilter => 'Active';

  @override
  String get fleetStatusInactiveFilter => 'Inactive';

  @override
  String get noTractorHeadsFound => 'No tractor heads found.';

  @override
  String get noTrailersFound => 'No trailers found.';

  @override
  String get noFleetMatchFilters =>
      'No fleet assets match the current search or filter.';

  @override
  String get fleetEditButton => 'Edit';

  @override
  String get fleetDeactivateButton => 'Deactivate';

  @override
  String get fleetReactivateButton => 'Reactivate';

  @override
  String get fleetDetailsButton => 'Details';

  @override
  String get fleetConfirmDeactivateTitle => 'Confirm deactivation';

  @override
  String get fleetConfirmReactivateTitle => 'Confirm reactivation';

  @override
  String get fleetConfirmDeactivateMessage =>
      'Do you want to deactivate this asset?';

  @override
  String get fleetConfirmReactivateMessage =>
      'Do you want to reactivate this asset?';

  @override
  String get vehicleStatusAvailable => 'Available';

  @override
  String get vehicleStatusOnTrip => 'On trip';

  @override
  String get vehicleStatusLoading => 'Loading';

  @override
  String get vehicleStatusUnloading => 'Unloading';

  @override
  String get vehicleStatusMaintenance => 'Maintenance';

  @override
  String get vehicleStatusStopped => 'Stopped';

  @override
  String get vehicleStatusInactive => 'Inactive';

  @override
  String get fleetBasicInfo => 'Basic information';

  @override
  String get fleetAccountability => 'Accountability';

  @override
  String get fleetActivityTimeline => 'Activity timeline';

  @override
  String get fleetCreatedBy => 'Created by';

  @override
  String get fleetCreatedRole => 'Created role';

  @override
  String get fleetCreatedAt => 'Created at';

  @override
  String get fleetLastActivityBy => 'Last activity by';

  @override
  String get fleetLastActivityRole => 'Last activity role';

  @override
  String get fleetLastActivityAt => 'Last activity at';

  @override
  String get fleetLoadingActivity => 'Loading activity...';

  @override
  String get fleetNoActivityFound => 'No activity found for this asset.';

  @override
  String get fleetUnknownUser => 'Unknown user';

  @override
  String get fleetNotAvailable => 'Not available';

  @override
  String get fleetChanges => 'Changes';

  @override
  String fleetDetailsTitle(String plateNumber) {
    return 'Fleet asset details: $plateNumber';
  }

  @override
  String get fleetAuditActionCreated => 'Created';

  @override
  String get fleetAuditActionUpdated => 'Updated';

  @override
  String get fleetAuditActionDeactivated => 'Deactivated';

  @override
  String get fleetAuditActionReactivated => 'Reactivated';

  @override
  String get fleetAuditActionStatusChanged => 'Status changed';

  @override
  String get driverFinanceTitle => 'Driver finance';

  @override
  String get driverBalancePlaceholderDescription =>
      'Negative balance means the driver owes the company. Positive balance means the company owes the driver.';

  @override
  String get addDriverAdvanceButton => 'Add advance';

  @override
  String get addDriverChargeButton => 'Add driver charge';

  @override
  String get addDriverAdvanceTitle => 'Add driver advance';

  @override
  String get addDriverChargeTitle => 'Add driver charge';

  @override
  String get driverMovementAmountLabel => 'Amount';

  @override
  String get driverMovementDateLabel => 'Date';

  @override
  String get driverMovementTripPickerComingSoon =>
      'A related trip is optional. Leave it empty for a general driver charge.';

  @override
  String get driverMovementRelatedTripLabel => 'Related trip';

  @override
  String get driverMovementGeneralChargeOption =>
      'General driver charge without trip link';

  @override
  String get loadingDriverTripOptions => 'Loading driver trips...';

  @override
  String get noDriverTripsForCharge =>
      'No trips assigned to this driver yet. You can save a general driver charge.';

  @override
  String get driverMovementNotesLabel => 'Notes';

  @override
  String get totalAdvancesLabel => 'Total advances';

  @override
  String get totalDriverChargesLabel => 'Total driver charges';

  @override
  String get netDriverBalanceLabel => 'Current balance';

  @override
  String driverBalanceDriverOwesCompany(String amount) {
    return 'Driver owes company: $amount';
  }

  @override
  String driverBalanceCompanyOwesDriver(String amount) {
    return 'Company owes driver: $amount';
  }

  @override
  String get driverBalanceSettled => 'Balance settled';

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
  String get driverMovementTypeDriverCharge => 'Driver charge';

  @override
  String get driverMovementTypeCashReturn => 'Cash return';

  @override
  String get companyExpensesTitle => 'Company expenses';

  @override
  String get addCompanyExpenseButton => 'Add expense';

  @override
  String get addCompanyExpenseTitle => 'Add company expense';

  @override
  String get editCompanyExpenseTitle => 'Edit company expense';

  @override
  String get companyExpenseCategoryLabel => 'Category';

  @override
  String get companyExpenseCategoryRequired => 'Category is required.';

  @override
  String get companyExpenseAmountLabel => 'Amount';

  @override
  String get companyExpenseDateLabel => 'Date';

  @override
  String get companyExpenseReferenceLabel => 'Reference number';

  @override
  String get companyExpenseNotesLabel => 'Notes';

  @override
  String get companyExpenseAmountInvalid =>
      'Enter a valid amount greater than zero.';

  @override
  String get searchCompanyExpensesHint =>
      'Search category, amount, reference, or notes';

  @override
  String get includeVoidedCompanyExpenses => 'Show voided';

  @override
  String get noCompanyExpensesFound => 'No company expenses found.';

  @override
  String get noCompanyExpensesMatchFilters =>
      'No company expenses match the current search.';

  @override
  String get companyExpenseVoidedStatus => 'Voided';

  @override
  String get companyExpenseActiveStatus => 'Active';

  @override
  String get voidCompanyExpenseButton => 'Void';

  @override
  String get voidCompanyExpenseTitle => 'Void company expense';

  @override
  String get voidCompanyExpenseMessage =>
      'Do you want to void this expense? It will remain in the history as voided.';

  @override
  String get voidReasonLabel => 'Void reason';

  @override
  String get confirmButton => 'Confirm';

  @override
  String companyExpenseCategoryLine(String categoryName) {
    return 'Category: $categoryName';
  }

  @override
  String companyExpenseAmountLine(String amount) {
    return 'Amount: $amount';
  }

  @override
  String companyExpenseDateLine(String date) {
    return 'Date: $date';
  }

  @override
  String companyExpenseReferenceLine(String reference) {
    return 'Reference: $reference';
  }

  @override
  String get companyExpenseCategoryVehicleMaintenance => 'Vehicle maintenance';

  @override
  String get companyExpenseCategorySpareParts => 'Spare parts';

  @override
  String get companyExpenseCategoryTires => 'Tires';

  @override
  String get companyExpenseCategoryOilsAndFluids => 'Oils and fluids';

  @override
  String get companyExpenseCategoryLicensesAndRenewals =>
      'Licenses and renewals';

  @override
  String get companyExpenseCategoryOfficeExpenses => 'Office expenses';

  @override
  String get companyExpenseCategoryRent => 'Rent';

  @override
  String get companyExpenseCategorySalaries => 'Salaries';

  @override
  String get companyExpenseCategoryAdminCosts => 'Admin costs';

  @override
  String get companyExpenseCategoryFines => 'Fines';

  @override
  String get companyExpenseCategoryOther => 'Other';

  @override
  String get failureUnexpectedError => 'Unexpected error occurred.';

  @override
  String get failureServerError => 'Server error occurred.';

  @override
  String get failureValidationCompanyIdRequired => 'Company id is required.';

  @override
  String get failureValidationCompanyContextRequired =>
      'Company context is required.';

  @override
  String get failureCompanyNotAvailable =>
      'Selected company is not available for the current user.';

  @override
  String get failurePermissionCompanyUsersView =>
      'This role cannot view company users.';

  @override
  String get failurePermissionCustomersView =>
      'Customers access is not allowed.';

  @override
  String get failurePermissionCustomersManagement =>
      'Customers management is not allowed.';

  @override
  String get failureValidationCustomerIdRequired => 'Customer id is required.';

  @override
  String get failureValidationCustomerNameRequired =>
      'Customer name is required.';

  @override
  String get failureValidationCreditLimitNegative =>
      'Credit limit cannot be negative.';

  @override
  String get failurePermissionDriversView =>
      'You are not allowed to view drivers.';

  @override
  String get failurePermissionDriversManagement =>
      'Drivers management is not allowed.';

  @override
  String get failureValidationDriverIdRequired => 'Driver id is required.';

  @override
  String get failureValidationDriverNameRequired => 'Driver name is required.';

  @override
  String get failureValidationDriverImageTooLarge =>
      'Selected image must be 5 MB or smaller.';

  @override
  String get failureValidationDriverImageTypeUnsupported =>
      'Selected image type is not supported. Use JPG, PNG, WebP, HEIC, or HEIF.';

  @override
  String get failurePermissionFleetManagement =>
      'Fleet management is not allowed.';

  @override
  String get failurePermissionFleetView => 'You are not allowed to view fleet.';

  @override
  String get failureValidationFleetPlateRequired => 'Plate number is required.';

  @override
  String get failureValidationFleetFuelConsumptionNegative =>
      'Expected fuel consumption cannot be negative.';

  @override
  String get failurePermissionRoutesManagement =>
      'Routes management is not allowed.';

  @override
  String get failurePermissionRoutesView =>
      'You are not allowed to view routes.';

  @override
  String get failureValidationRouteLoadingLocationRequired =>
      'Loading location is required.';

  @override
  String get failureValidationRouteUnloadingLocationRequired =>
      'Unloading location is required.';

  @override
  String get failureValidationRouteFreightPriceNegative =>
      'Default freight price cannot be negative.';

  @override
  String get failureValidationTripIdRequired => 'Trip id is required.';

  @override
  String get failurePermissionTripExpensesView =>
      'Trip expenses access is not allowed.';

  @override
  String get failurePermissionTripExpensesManagement =>
      'Trip expenses management is not allowed.';

  @override
  String get failureValidationTripExpenseIdRequired =>
      'Trip expense id is required.';

  @override
  String get failureValidationTripExpenseTypeRequired =>
      'Expense type is required.';

  @override
  String get failureValidationTripExpenseNameRequired =>
      'Expense name is required.';

  @override
  String get failureValidationTripExpenseAmountPositive =>
      'Expense amount must be greater than zero.';

  @override
  String get failurePermissionDriverFinanceView =>
      'Driver finance access is not allowed.';

  @override
  String get failurePermissionDriverFinanceManagement =>
      'Driver finance management is not allowed.';

  @override
  String get failureValidationDriverFinanceAmountPositive =>
      'Driver financial movement amount must be greater than zero.';

  @override
  String get failurePermissionCompanyExpensesView =>
      'Company expenses access is not allowed.';

  @override
  String get failurePermissionCompanyExpensesManagement =>
      'Company expenses management is not allowed.';

  @override
  String get failureValidationCompanyExpenseIdRequired =>
      'Company expense id is required.';

  @override
  String get failureValidationCompanyExpenseCategoryRequired =>
      'Company expense category is required.';

  @override
  String get failureValidationCompanyExpenseAmountPositive =>
      'Company expense amount must be greater than zero.';

  @override
  String get failureValidationAuditEntityIdRequired =>
      'Audit entity id is required.';

  @override
  String get failureValidationAuditDescriptionRequired =>
      'Audit description is required.';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String get profileDetailsNotSetYet => 'Profile details not set yet';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsReportLabel => 'Report';

  @override
  String get reportsFromDate => 'From date';

  @override
  String get reportsToDate => 'To date';

  @override
  String get reportsSelectDate => 'Select date';

  @override
  String get reportsApplyFilters => 'Apply';

  @override
  String get reportsClearFilters => 'Clear dates';

  @override
  String get reportsLoading => 'Loading report...';

  @override
  String get reportsRetry => 'Retry';

  @override
  String get reportsNoRows => 'No data for the selected period.';

  @override
  String get reportsNoAccess => 'No reports are available for this role.';

  @override
  String get reportsUnassigned => 'Unassigned';

  @override
  String get reportsAllDates => 'All dates';

  @override
  String get reportsNotAvailable => 'Not available';

  @override
  String get reportsTrip => 'Trip';

  @override
  String get reportsDate => 'Date';

  @override
  String get reportsCustomer => 'Customer';

  @override
  String get reportsDriver => 'Driver';

  @override
  String get reportsTractorHead => 'Tractor head';

  @override
  String get reportsTrailer => 'Trailer';

  @override
  String get reportsRoute => 'Route';

  @override
  String get reportsStatus => 'Status';

  @override
  String get reportsTripsCount => 'Trips';

  @override
  String get reportsLoadingOrder => 'Loading order';

  @override
  String get reportsWaybill => 'Waybill';

  @override
  String get reportsExpense => 'Expense';

  @override
  String get reportsPaidBy => 'Paid by';

  @override
  String get reportsAmount => 'Amount';

  @override
  String get reportsTotalExpenses => 'Total expenses';

  @override
  String get reportsFreight => 'Freight';

  @override
  String get reportsNetProfit => 'Net profit';

  @override
  String get reportsTotalFreight => 'Total freight';

  @override
  String get reportsTotalNetProfit => 'Total net profit';

  @override
  String get reportsInvoice => 'Invoice';

  @override
  String get reportsIssueDate => 'Issue date';

  @override
  String get reportsDueDate => 'Due date';

  @override
  String get reportsTotal => 'Total';

  @override
  String get reportsPaid => 'Paid';

  @override
  String get reportsRemaining => 'Remaining';

  @override
  String get reportsTotalOutstanding => 'Total outstanding';

  @override
  String get reportsTypeDailyTrips => 'Daily trips';

  @override
  String get reportsTypeTripsByCustomer => 'Trips by customer';

  @override
  String get reportsTypeTripsByDriver => 'Trips by driver';

  @override
  String get reportsTypeTripsByTractorHead => 'Trips by tractor head';

  @override
  String get reportsTypeTripsByTrailer => 'Trips by trailer';

  @override
  String get reportsTypeTripExpenses => 'Trip expenses';

  @override
  String get reportsTypeTripNetProfit => 'Trip net profit';

  @override
  String get reportsTypeOpenInvoices => 'Open invoices';

  @override
  String reportsGroupTrips(int count) {
    return '$count trips';
  }

  @override
  String reportsDateRange(String from, String to) {
    return 'Period: $from — $to';
  }

  @override
  String get reportsPaidByCompany => 'Company';

  @override
  String get reportsPaidByDriverAdvance => 'Driver advance';

  @override
  String get reportsPaidByDriverCash => 'Driver cash';

  @override
  String get reportsPaidByCustomer => 'Customer';

  @override
  String get reportsPaidByOther => 'Other';

  @override
  String get reportsInvoiceStatusDraft => 'Draft';

  @override
  String get reportsInvoiceStatusIssued => 'Issued';

  @override
  String get reportsInvoiceStatusPartiallyPaid => 'Partially paid';

  @override
  String get reportsInvoiceStatusPaid => 'Paid';

  @override
  String get reportsInvoiceStatusCancelled => 'Cancelled';

  @override
  String get reportsPermissionFailure =>
      'This role cannot view the selected report.';

  @override
  String get reportsInvalidDateRangeFailure =>
      'The from date cannot be after the to date.';

  @override
  String get reportsRegionalSettingsFailure =>
      'Configure the company currency and business timezone first.';

  @override
  String get reportsCompanyNotFoundFailure =>
      'The current company could not be found.';

  @override
  String get reportsSourceInvalidFailure =>
      'The report data is inconsistent. Reload and try again.';

  @override
  String get reportsCurrencyMismatchFailure =>
      'Report financial data does not match the company currency.';

  @override
  String get reportsFinancialDataInvalidFailure =>
      'Report financial data contains an invalid amount or balance.';

  @override
  String get reportsInvoiceBalanceInvalidFailure =>
      'An invoice balance is inconsistent with its status and payments.';

  @override
  String get reportsLoadFailed => 'The report could not be loaded.';

  @override
  String get tripDetailsHeaderTitle => 'Trip details';

  @override
  String get tripsTitle => 'Trips';

  @override
  String get addTripButton => 'Add trip';

  @override
  String get addTripTitle => 'Add trip';

  @override
  String get editTripTitle => 'Edit trip';

  @override
  String get searchTripsHint => 'Search trips';

  @override
  String get noTripsFound => 'No trips found.';

  @override
  String get noTripsMatchFilters =>
      'No trips match the current search or filter.';

  @override
  String get tripCustomerHeader => 'Customer';

  @override
  String get tripRouteHeader => 'Route';

  @override
  String get tripDriverHeader => 'Driver';

  @override
  String get tripVehicleHeader => 'Vehicle';

  @override
  String get tripTractorHeadLabel => 'Tractor head';

  @override
  String get tripTrailerLabel => 'Trailer';

  @override
  String get tripLoadingOrderHeader => 'Loading order';

  @override
  String get tripWaybillHeader => 'Waybill';

  @override
  String get tripQuantityHeader => 'Quantity';

  @override
  String get tripTonsSuffix => 't';

  @override
  String get tripFreightPriceHeader => 'Freight';

  @override
  String get tripTotalExpensesLabel => 'Total expenses';

  @override
  String get tripNetProfitHeader => 'Net profit';

  @override
  String get tripViewDetails => 'View details';

  @override
  String get tripEditButton => 'Edit';

  @override
  String get tripUpdateStatus => 'Update status';

  @override
  String get tripEmptyValue => '-';

  @override
  String get tripOptionalNone => 'None';

  @override
  String get tripScheduledLoadingAtLabel => 'Scheduled loading';

  @override
  String get tripScheduledDeliveryAtLabel => 'Scheduled delivery';

  @override
  String get tripActualLoadingAtLabel => 'Actual loading';

  @override
  String get tripActualDeliveryAtLabel => 'Actual delivery';

  @override
  String get tripBasicInfo => 'Basic information';

  @override
  String get tripAccountability => 'Accountability';

  @override
  String get tripActivityTimeline => 'Activity timeline';

  @override
  String get tripStatusHistoryTitle => 'Status history';

  @override
  String get tripExpensesTitle => 'Trip expenses';

  @override
  String get tripLoadingExpenses => 'Loading expenses...';

  @override
  String get tripNoExpensesFound => 'No expenses yet.';

  @override
  String get tripAddExpenseButton => 'Add expense';

  @override
  String get tripEditExpenseTitle => 'Edit expense';

  @override
  String get tripAddExpenseTitle => 'Add expense';

  @override
  String get tripExpenseNameLabel => 'Expense name';

  @override
  String get tripExpenseTypeLabel => 'Expense type';

  @override
  String get tripExpenseTypeRequired => 'Expense type is required.';

  @override
  String get tripExpenseAmountLabel => 'Amount';

  @override
  String get tripExpensePaidByLabel => 'Paid by';

  @override
  String get tripExpenseDateLabel => 'Expense date';

  @override
  String get tripExpenseDateHelperText => 'Example: 2026-06-26';

  @override
  String get tripExpenseDateInvalid => 'Enter a valid date.';

  @override
  String get tripExpenseNameRequired => 'Expense name is required.';

  @override
  String get tripExpenseAmountPositive => 'Amount must be greater than zero.';

  @override
  String get tripExpenseTypesUnavailable => 'Expense types are unavailable.';

  @override
  String get tripLoadingActivity => 'Loading activity...';

  @override
  String get tripLoadingStatusHistory => 'Loading status history...';

  @override
  String get tripLoadingLookups => 'Loading form data...';

  @override
  String get tripRequiredLookupsMissing =>
      'At least one customer and one route are required before creating a trip.';

  @override
  String get tripNoActivityFound => 'No activity yet.';

  @override
  String get tripNoStatusHistoryFound => 'No status history yet.';

  @override
  String get tripCreatedBy => 'Created by';

  @override
  String get tripCreatedRole => 'Created role';

  @override
  String get tripCreatedAt => 'Created at';

  @override
  String get tripLastActivityBy => 'Last activity by';

  @override
  String get tripLastActivityRole => 'Last activity role';

  @override
  String get tripLastActivityAt => 'Last activity at';

  @override
  String get tripUnknownUser => 'Unknown user';

  @override
  String get tripChanges => 'Changes';

  @override
  String get tripAuditDetails => 'Details';

  @override
  String get tripCloseButton => 'Close';

  @override
  String get tripNextStatusLabel => 'Next status';

  @override
  String get tripStatusNotesLabel => 'Status change notes';

  @override
  String get tripNoAvailableStatusActions =>
      'No available status actions for the current status.';

  @override
  String get tripCustomerRequired => 'Customer is required.';

  @override
  String get tripRouteRequired => 'Route is required.';

  @override
  String get tripNumberInvalid => 'Enter a valid non-negative number.';

  @override
  String get tripDateTimeHelperText => 'Optional - example: 2026-06-20 14:30';

  @override
  String get tripDateTimeInvalid => 'Enter a valid date and time.';

  @override
  String get tripDeliveryBeforeLoadingInvalid =>
      'Delivery cannot be before loading.';

  @override
  String get tripsStatusAllFilter => 'All';

  @override
  String get tripsStatusOpenFilter => 'Open';

  @override
  String get tripsStatusCreatedFilter => 'Created';

  @override
  String get tripsStatusAssignedFilter => 'Assigned';

  @override
  String get tripsStatusLoadedFilter => 'Loaded';

  @override
  String get tripsStatusOnRoadFilter => 'On road';

  @override
  String get tripsStatusArrivedFilter => 'Arrived';

  @override
  String get tripsStatusDeliveredFilter => 'Delivered';

  @override
  String get tripsStatusDocumentsReceivedFilter => 'Documents received';

  @override
  String get tripsStatusInvoicedFilter => 'Invoiced';

  @override
  String get tripsStatusPaidFilter => 'Paid';

  @override
  String get tripsStatusCancelledFilter => 'Cancelled';

  @override
  String tripCurrentStatusLine(String status) {
    return 'Current status: $status';
  }

  @override
  String tripStatusHistoryLine(String oldStatus, String newStatus) {
    return 'From $oldStatus to $newStatus';
  }

  @override
  String tripChangedByLine(String actor, String role, String dateTime) {
    return '$actor ($role) - $dateTime';
  }

  @override
  String tripAuditTimelineHeader(String actor, String role, String dateTime) {
    return '$actor ($role) - $dateTime';
  }

  @override
  String tripAuditChangeLine(String label, String oldValue, String newValue) {
    return '$label: from $oldValue to $newValue';
  }

  @override
  String tripAuditDetailLine(String label, String value) {
    return '$label: $value';
  }

  @override
  String tripDetailsTitleText(String name) {
    return 'Trip details: $name';
  }

  @override
  String tripUpdateStatusTitleText(String name) {
    return 'Update trip status: $name';
  }

  @override
  String get tripExpensePaidByCompany => 'Company';

  @override
  String get tripExpensePaidByDriverAdvance => 'Driver advance';

  @override
  String get tripExpensePaidByDriverCash => 'Driver cash';

  @override
  String get tripExpensePaidByCustomer => 'Customer';

  @override
  String get tripExpensePaidByOther => 'Other';

  @override
  String get tripExpenseTypeFuel => 'Fuel';

  @override
  String get tripExpenseTypeRoadFees => 'Road fees';

  @override
  String get tripExpenseTypeWeighbridge => 'Weighbridge';

  @override
  String get tripExpenseTypeLoading => 'Loading';

  @override
  String get tripExpenseTypeUnloading => 'Unloading';

  @override
  String get tripExpenseTypeFines => 'Fines';

  @override
  String get tripExpenseTypeEmergencyMaintenance => 'Emergency maintenance';

  @override
  String get tripExpenseTypeDriverAdvance => 'Driver advance';

  @override
  String get tripExpenseTypeOther => 'Other';

  @override
  String get tripAuditActionCreated => 'Created';

  @override
  String get tripAuditActionUpdated => 'Updated';

  @override
  String get tripAuditActionStatusChanged => 'Status changed';

  @override
  String get tripAuditActionDeactivated => 'Deactivated';

  @override
  String get tripAuditActionReactivated => 'Reactivated';

  @override
  String get tripAuditRoleOwner => 'Owner';

  @override
  String get tripAuditRoleAdmin => 'Admin';

  @override
  String get tripAuditRoleOperations => 'Operations';

  @override
  String get tripAuditRoleAccountant => 'Accountant';

  @override
  String get tripAuditRoleViewer => 'Viewer';

  @override
  String get tripAuditRoleDriver => 'Driver';

  @override
  String get tripAuditFieldExpenseId => 'Expense id';

  @override
  String get tripAuditFieldTractorPlate => 'Tractor plate';

  @override
  String get tripAuditFieldTrailerPlate => 'Trailer plate';
}
