import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'H.O.R.U.S System'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Heavy Operations & Route Unified System'**
  String get appSubtitle;

  /// No description provided for @launchDescription.
  ///
  /// In en, this message translates to:
  /// **'SaaS platform for heavy transport operations.'**
  String get launchDescription;

  /// No description provided for @architectureBadge.
  ///
  /// In en, this message translates to:
  /// **'Clean Architecture by the book • SOLID Principles'**
  String get architectureBadge;

  /// No description provided for @appShellDashboardLabel.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get appShellDashboardLabel;

  /// No description provided for @appShellDashboardDescription.
  ///
  /// In en, this message translates to:
  /// **'Live overview for company operations and finance.'**
  String get appShellDashboardDescription;

  /// No description provided for @appShellCustomersLabel.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get appShellCustomersLabel;

  /// No description provided for @appShellCustomersDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage customer master data and account activity.'**
  String get appShellCustomersDescription;

  /// No description provided for @appShellDriversLabel.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get appShellDriversLabel;

  /// No description provided for @appShellDriversDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage drivers, status, and driver actions.'**
  String get appShellDriversDescription;

  /// No description provided for @appShellFleetLabel.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get appShellFleetLabel;

  /// No description provided for @appShellFleetDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage tractor heads, trailers, and availability.'**
  String get appShellFleetDescription;

  /// No description provided for @appShellRoutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get appShellRoutesLabel;

  /// No description provided for @appShellRoutesDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage loading points, delivery points, and lanes.'**
  String get appShellRoutesDescription;

  /// No description provided for @appShellTripsLabel.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get appShellTripsLabel;

  /// No description provided for @appShellTripsDescription.
  ///
  /// In en, this message translates to:
  /// **'Create, track, and update trips.'**
  String get appShellTripsDescription;

  /// No description provided for @appShellExpensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get appShellExpensesLabel;

  /// No description provided for @appShellExpensesDescription.
  ///
  /// In en, this message translates to:
  /// **'Track trip costs, fees, and financial movements.'**
  String get appShellExpensesDescription;

  /// No description provided for @appShellInvoicesLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get appShellInvoicesLabel;

  /// No description provided for @appShellInvoicesDescription.
  ///
  /// In en, this message translates to:
  /// **'Create invoices, register payments, and track balances.'**
  String get appShellInvoicesDescription;

  /// No description provided for @appShellReportsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get appShellReportsLabel;

  /// No description provided for @appShellReportsDescription.
  ///
  /// In en, this message translates to:
  /// **'Review operational and financial reports.'**
  String get appShellReportsDescription;

  /// No description provided for @appShellSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get appShellSettingsLabel;

  /// No description provided for @appShellSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage company settings, users, roles, and access.'**
  String get appShellSettingsDescription;

  /// No description provided for @appShellMoreLabel.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get appShellMoreLabel;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @companyWithName.
  ///
  /// In en, this message translates to:
  /// **'Company: {companyName}'**
  String companyWithName(String companyName);

  /// No description provided for @roleWithName.
  ///
  /// In en, this message translates to:
  /// **'Role: {roleName}'**
  String roleWithName(String roleName);

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage users'**
  String get manageUsers;

  /// No description provided for @companySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Company settings'**
  String get companySettingsTitle;

  /// No description provided for @noPermissionManageUsers.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to manage users.'**
  String get noPermissionManageUsers;

  /// No description provided for @switchToArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get switchToArabic;

  /// No description provided for @switchToEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get switchToEnglish;

  /// No description provided for @adaptiveAccessNotice.
  ///
  /// In en, this message translates to:
  /// **'Same modules on every device. The screen layout changes, not the available actions.'**
  String get adaptiveAccessNotice;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get roleOperations;

  /// No description provided for @roleAccountant.
  ///
  /// In en, this message translates to:
  /// **'Accountant'**
  String get roleAccountant;

  /// No description provided for @roleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleViewer;

  /// No description provided for @roleDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleDriver;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to H.O.R.U.S System'**
  String get loginWelcomeTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue managing heavy transport operations.'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get passwordRequired;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @createNewAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get createNewAccountButton;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your H.O.R.U.S account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full name and phone are required for company user management.'**
  String get registerSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required.'**
  String get fullNameRequired;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required.'**
  String get phoneNumberRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordMinLength;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountButton;

  /// No description provided for @checkYourEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmailTitle;

  /// No description provided for @emailConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'We sent a confirmation link to {email}. Open the email, confirm your account, then return to H.O.R.U.S System and log in.'**
  String emailConfirmationMessage(String email);

  /// No description provided for @backToLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLoginButton;

  /// No description provided for @createCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Create company'**
  String get createCompanyTitle;

  /// No description provided for @createCompanyFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your company'**
  String get createCompanyFormTitle;

  /// No description provided for @createCompanySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up the first company workspace for H.O.R.U.S System.'**
  String get createCompanySubtitle;

  /// No description provided for @companyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get companyNameLabel;

  /// No description provided for @companyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Company name is required.'**
  String get companyNameRequired;

  /// No description provided for @businessTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Business type'**
  String get businessTypeLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @createCompanyButton.
  ///
  /// In en, this message translates to:
  /// **'Create company'**
  String get createCompanyButton;

  /// No description provided for @companyContextLoadedTitle.
  ///
  /// In en, this message translates to:
  /// **'Company context loaded'**
  String get companyContextLoadedTitle;

  /// No description provided for @companyContextNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step: current company context and app shell.'**
  String get companyContextNextStep;

  /// No description provided for @currentCompanyContextRequired.
  ///
  /// In en, this message translates to:
  /// **'Current company context is required.'**
  String get currentCompanyContextRequired;

  /// No description provided for @companyUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Users'**
  String get companyUsersTitle;

  /// No description provided for @inviteButton.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get inviteButton;

  /// No description provided for @noCompanyUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No company users found.'**
  String get noCompanyUsersFound;

  /// No description provided for @inviteFlowComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Invite flow will be implemented in a later issue.'**
  String get inviteFlowComingSoon;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @inactiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveStatus;

  /// No description provided for @roleLine.
  ///
  /// In en, this message translates to:
  /// **'Role: {roleName}'**
  String roleLine(String roleName);

  /// No description provided for @statusLine.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusLine(String status);

  /// No description provided for @incompleteProfileMessage.
  ///
  /// In en, this message translates to:
  /// **'Profile is incomplete. Ask this user to complete their profile.'**
  String get incompleteProfileMessage;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @addCustomerButton.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get addCustomerButton;

  /// No description provided for @addCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get addCustomerTitle;

  /// No description provided for @editCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get editCustomerTitle;

  /// No description provided for @editCustomerButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editCustomerButton;

  /// No description provided for @deactivateCustomerButton.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivateCustomerButton;

  /// No description provided for @reactivateCustomerButton.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivateCustomerButton;

  /// No description provided for @searchCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers by name, contact, phone, email, city, country, or TRN'**
  String get searchCustomersHint;

  /// No description provided for @customersStatusAllFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get customersStatusAllFilter;

  /// No description provided for @customersStatusActiveFilter.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get customersStatusActiveFilter;

  /// No description provided for @customersStatusInactiveFilter.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get customersStatusInactiveFilter;

  /// No description provided for @customerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get customerNameLabel;

  /// No description provided for @customerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer name is required.'**
  String get customerNameRequired;

  /// No description provided for @contactPersonLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact person'**
  String get contactPersonLabel;

  /// No description provided for @taxRegistrationNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'TRN / Tax number'**
  String get taxRegistrationNumberLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @creditLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get creditLimitLabel;

  /// No description provided for @creditLimitInvalid.
  ///
  /// In en, this message translates to:
  /// **'Credit limit must be a valid non-negative number.'**
  String get creditLimitInvalid;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @noCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found.'**
  String get noCustomersFound;

  /// No description provided for @noCustomersMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No customers match the current search or status filter.'**
  String get noCustomersMatchFilters;

  /// No description provided for @customerNameHeader.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerNameHeader;

  /// No description provided for @contactHeader.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactHeader;

  /// No description provided for @statusHeader.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusHeader;

  /// No description provided for @actionsHeader.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsHeader;

  /// No description provided for @contactPersonLine.
  ///
  /// In en, this message translates to:
  /// **'Contact: {contactPerson}'**
  String contactPersonLine(String contactPerson);

  /// No description provided for @phoneLine.
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}'**
  String phoneLine(String phone);

  /// No description provided for @emailLine.
  ///
  /// In en, this message translates to:
  /// **'Email: {email}'**
  String emailLine(String email);

  /// No description provided for @cityLine.
  ///
  /// In en, this message translates to:
  /// **'City: {city}'**
  String cityLine(String city);

  /// No description provided for @auditTimelineHeader.
  ///
  /// In en, this message translates to:
  /// **'{actorName} • {role} • {dateTime}'**
  String auditTimelineHeader(String actorName, String role, String dateTime);

  /// No description provided for @auditChangeLine.
  ///
  /// In en, this message translates to:
  /// **'{field}: {oldValue} → {newValue}'**
  String auditChangeLine(String field, String oldValue, String newValue);

  /// No description provided for @routesTitle.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routesTitle;

  /// No description provided for @addRouteButton.
  ///
  /// In en, this message translates to:
  /// **'Add route'**
  String get addRouteButton;

  /// No description provided for @addRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Add route'**
  String get addRouteTitle;

  /// No description provided for @editRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit route'**
  String get editRouteTitle;

  /// No description provided for @loadingLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading location'**
  String get loadingLocationLabel;

  /// No description provided for @unloadingLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Unloading location'**
  String get unloadingLocationLabel;

  /// No description provided for @governorateFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading governorate'**
  String get governorateFromLabel;

  /// No description provided for @governorateToLabel.
  ///
  /// In en, this message translates to:
  /// **'Unloading governorate'**
  String get governorateToLabel;

  /// No description provided for @defaultFreightPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Default freight price'**
  String get defaultFreightPriceLabel;

  /// No description provided for @routeNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get routeNotesLabel;

  /// No description provided for @loadingLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Loading location is required.'**
  String get loadingLocationRequired;

  /// No description provided for @unloadingLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Unloading location is required.'**
  String get unloadingLocationRequired;

  /// No description provided for @defaultFreightPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid non-negative number.'**
  String get defaultFreightPriceInvalid;

  /// No description provided for @searchRoutesHint.
  ///
  /// In en, this message translates to:
  /// **'Search routes'**
  String get searchRoutesHint;

  /// No description provided for @routesStatusAllFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get routesStatusAllFilter;

  /// No description provided for @routesStatusActiveFilter.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get routesStatusActiveFilter;

  /// No description provided for @routesStatusInactiveFilter.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get routesStatusInactiveFilter;

  /// No description provided for @noRoutesFound.
  ///
  /// In en, this message translates to:
  /// **'No routes found.'**
  String get noRoutesFound;

  /// No description provided for @noRoutesMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No routes match the current search or filter.'**
  String get noRoutesMatchFilters;

  /// No description provided for @routeDeactivateButton.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get routeDeactivateButton;

  /// No description provided for @routeReactivateButton.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get routeReactivateButton;

  /// No description provided for @confirmRouteDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm route deactivation'**
  String get confirmRouteDeactivateTitle;

  /// No description provided for @confirmRouteReactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm route reactivation'**
  String get confirmRouteReactivateTitle;

  /// No description provided for @confirmRouteDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to deactivate this route?'**
  String get confirmRouteDeactivateMessage;

  /// No description provided for @confirmRouteReactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to reactivate this route?'**
  String get confirmRouteReactivateMessage;

  /// No description provided for @routeLoadingHeader.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get routeLoadingHeader;

  /// No description provided for @routeUnloadingHeader.
  ///
  /// In en, this message translates to:
  /// **'Unloading'**
  String get routeUnloadingHeader;

  /// No description provided for @routeGovernoratesHeader.
  ///
  /// In en, this message translates to:
  /// **'Governorates'**
  String get routeGovernoratesHeader;

  /// No description provided for @routeDefaultPriceHeader.
  ///
  /// In en, this message translates to:
  /// **'Default price'**
  String get routeDefaultPriceHeader;

  /// No description provided for @routeStatusHeader.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get routeStatusHeader;

  /// No description provided for @routeActiveStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get routeActiveStatusLabel;

  /// No description provided for @routeInactiveStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get routeInactiveStatusLabel;

  /// No description provided for @routeEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get routeEditButton;

  /// No description provided for @routeViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get routeViewDetails;

  /// No description provided for @routeDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Route details: {name}'**
  String routeDetailsTitle(String name);

  /// No description provided for @routeBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get routeBasicInfo;

  /// No description provided for @routeAccountability.
  ///
  /// In en, this message translates to:
  /// **'Accountability'**
  String get routeAccountability;

  /// No description provided for @routeCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get routeCreatedBy;

  /// No description provided for @routeCreatedRole.
  ///
  /// In en, this message translates to:
  /// **'Created role'**
  String get routeCreatedRole;

  /// No description provided for @routeCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get routeCreatedAt;

  /// No description provided for @routeLastActivityBy.
  ///
  /// In en, this message translates to:
  /// **'Last activity by'**
  String get routeLastActivityBy;

  /// No description provided for @routeLastActivityRole.
  ///
  /// In en, this message translates to:
  /// **'Last activity role'**
  String get routeLastActivityRole;

  /// No description provided for @routeLastActivityAt.
  ///
  /// In en, this message translates to:
  /// **'Last activity at'**
  String get routeLastActivityAt;

  /// No description provided for @routeActivityTimeline.
  ///
  /// In en, this message translates to:
  /// **'Activity timeline'**
  String get routeActivityTimeline;

  /// No description provided for @routeLoadingActivity.
  ///
  /// In en, this message translates to:
  /// **'Loading activity...'**
  String get routeLoadingActivity;

  /// No description provided for @routeNoActivityFound.
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get routeNoActivityFound;

  /// No description provided for @routeChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get routeChanges;

  /// No description provided for @routeUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get routeUnknownUser;

  /// No description provided for @routeNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get routeNotAvailable;

  /// No description provided for @routeAuditActionCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get routeAuditActionCreated;

  /// No description provided for @routeAuditActionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get routeAuditActionUpdated;

  /// No description provided for @routeAuditActionDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get routeAuditActionDeactivated;

  /// No description provided for @routeAuditActionReactivated.
  ///
  /// In en, this message translates to:
  /// **'Reactivated'**
  String get routeAuditActionReactivated;

  /// No description provided for @routeAuditActionStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed'**
  String get routeAuditActionStatusChanged;

  /// No description provided for @routeAuditTimelineHeader.
  ///
  /// In en, this message translates to:
  /// **'{actor} ({role}) - {dateTime}'**
  String routeAuditTimelineHeader(String actor, String role, String dateTime);

  /// No description provided for @routeAuditChangeLine.
  ///
  /// In en, this message translates to:
  /// **'{label}: from {oldValue} to {newValue}'**
  String routeAuditChangeLine(String label, String oldValue, String newValue);

  /// No description provided for @fleetTitle.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get fleetTitle;

  /// No description provided for @tractorHeadsTab.
  ///
  /// In en, this message translates to:
  /// **'Tractor heads'**
  String get tractorHeadsTab;

  /// No description provided for @trailersTab.
  ///
  /// In en, this message translates to:
  /// **'Trailers'**
  String get trailersTab;

  /// No description provided for @addTractorHeadButton.
  ///
  /// In en, this message translates to:
  /// **'Add tractor head'**
  String get addTractorHeadButton;

  /// No description provided for @addTrailerButton.
  ///
  /// In en, this message translates to:
  /// **'Add trailer'**
  String get addTrailerButton;

  /// No description provided for @editTractorHeadTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit tractor head'**
  String get editTractorHeadTitle;

  /// No description provided for @editTrailerTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit trailer'**
  String get editTrailerTitle;

  /// No description provided for @plateNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get plateNumberLabel;

  /// No description provided for @plateNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Plate number is required.'**
  String get plateNumberRequired;

  /// No description provided for @vehicleStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle status'**
  String get vehicleStatusLabel;

  /// No description provided for @vehicleLicenseExpiryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'License expiry date'**
  String get vehicleLicenseExpiryDateLabel;

  /// No description provided for @expectedFuelConsumptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected fuel consumption'**
  String get expectedFuelConsumptionLabel;

  /// No description provided for @expectedFuelConsumptionInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid non-negative number.'**
  String get expectedFuelConsumptionInvalid;

  /// No description provided for @vehicleNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get vehicleNotesLabel;

  /// No description provided for @technicalNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Technical notes'**
  String get technicalNotesLabel;

  /// No description provided for @searchFleetHint.
  ///
  /// In en, this message translates to:
  /// **'Search by plate, status, or notes'**
  String get searchFleetHint;

  /// No description provided for @fleetStatusAllFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get fleetStatusAllFilter;

  /// No description provided for @fleetStatusActiveFilter.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get fleetStatusActiveFilter;

  /// No description provided for @fleetStatusInactiveFilter.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get fleetStatusInactiveFilter;

  /// No description provided for @noTractorHeadsFound.
  ///
  /// In en, this message translates to:
  /// **'No tractor heads found.'**
  String get noTractorHeadsFound;

  /// No description provided for @noTrailersFound.
  ///
  /// In en, this message translates to:
  /// **'No trailers found.'**
  String get noTrailersFound;

  /// No description provided for @noFleetMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No fleet assets match the current search or filter.'**
  String get noFleetMatchFilters;

  /// No description provided for @fleetEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get fleetEditButton;

  /// No description provided for @fleetDeactivateButton.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get fleetDeactivateButton;

  /// No description provided for @fleetReactivateButton.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get fleetReactivateButton;

  /// No description provided for @fleetDetailsButton.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get fleetDetailsButton;

  /// No description provided for @fleetConfirmDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm deactivation'**
  String get fleetConfirmDeactivateTitle;

  /// No description provided for @fleetConfirmReactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm reactivation'**
  String get fleetConfirmReactivateTitle;

  /// No description provided for @fleetConfirmDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to deactivate this asset?'**
  String get fleetConfirmDeactivateMessage;

  /// No description provided for @fleetConfirmReactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to reactivate this asset?'**
  String get fleetConfirmReactivateMessage;

  /// No description provided for @vehicleStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get vehicleStatusAvailable;

  /// No description provided for @vehicleStatusOnTrip.
  ///
  /// In en, this message translates to:
  /// **'On trip'**
  String get vehicleStatusOnTrip;

  /// No description provided for @vehicleStatusLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get vehicleStatusLoading;

  /// No description provided for @vehicleStatusUnloading.
  ///
  /// In en, this message translates to:
  /// **'Unloading'**
  String get vehicleStatusUnloading;

  /// No description provided for @vehicleStatusMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get vehicleStatusMaintenance;

  /// No description provided for @vehicleStatusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get vehicleStatusStopped;

  /// No description provided for @vehicleStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get vehicleStatusInactive;

  /// No description provided for @driverFinanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver finance'**
  String get driverFinanceTitle;

  /// No description provided for @driverBalancePlaceholderDescription.
  ///
  /// In en, this message translates to:
  /// **'Initial balance calculated from recorded advances and deductions. Monthly settlement will be implemented later.'**
  String get driverBalancePlaceholderDescription;

  /// No description provided for @addDriverAdvanceButton.
  ///
  /// In en, this message translates to:
  /// **'Add advance'**
  String get addDriverAdvanceButton;

  /// No description provided for @addDriverDeductionButton.
  ///
  /// In en, this message translates to:
  /// **'Add deduction'**
  String get addDriverDeductionButton;

  /// No description provided for @addDriverAdvanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add driver advance'**
  String get addDriverAdvanceTitle;

  /// No description provided for @addDriverDeductionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add driver deduction'**
  String get addDriverDeductionTitle;

  /// No description provided for @driverMovementAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get driverMovementAmountLabel;

  /// No description provided for @driverMovementDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get driverMovementDateLabel;

  /// No description provided for @driverMovementTripPickerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Trip selection will be added later. This deduction will be saved as a general deduction for now.'**
  String get driverMovementTripPickerComingSoon;

  /// No description provided for @driverMovementRelatedTripLabel.
  ///
  /// In en, this message translates to:
  /// **'Related trip'**
  String get driverMovementRelatedTripLabel;

  /// No description provided for @driverMovementGeneralDeductionOption.
  ///
  /// In en, this message translates to:
  /// **'General deduction without trip link'**
  String get driverMovementGeneralDeductionOption;

  /// No description provided for @loadingDriverTripOptions.
  ///
  /// In en, this message translates to:
  /// **'Loading driver trips...'**
  String get loadingDriverTripOptions;

  /// No description provided for @noDriverTripsForDeduction.
  ///
  /// In en, this message translates to:
  /// **'No trips assigned to this driver yet. You can save it as a general deduction.'**
  String get noDriverTripsForDeduction;

  /// No description provided for @driverMovementNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get driverMovementNotesLabel;

  /// No description provided for @totalAdvancesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total advances'**
  String get totalAdvancesLabel;

  /// No description provided for @totalDeductionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total deductions'**
  String get totalDeductionsLabel;

  /// No description provided for @netDriverBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get netDriverBalanceLabel;

  /// No description provided for @noDriverFinancialMovements.
  ///
  /// In en, this message translates to:
  /// **'No financial movements yet.'**
  String get noDriverFinancialMovements;

  /// No description provided for @loadingDriverFinancialMovements.
  ///
  /// In en, this message translates to:
  /// **'Loading driver financial movements...'**
  String get loadingDriverFinancialMovements;

  /// No description provided for @savingDriverFinancialMovement.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingDriverFinancialMovement;

  /// No description provided for @invalidDriverMovementAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount greater than zero.'**
  String get invalidDriverMovementAmount;

  /// No description provided for @driverMovementTripLine.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get driverMovementTripLine;

  /// No description provided for @driverMovementTypeAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get driverMovementTypeAdvance;

  /// No description provided for @driverMovementTypeDeduction.
  ///
  /// In en, this message translates to:
  /// **'Deduction'**
  String get driverMovementTypeDeduction;

  /// No description provided for @companyExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Company expenses'**
  String get companyExpensesTitle;

  /// No description provided for @addCompanyExpenseButton.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addCompanyExpenseButton;

  /// No description provided for @addCompanyExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add company expense'**
  String get addCompanyExpenseTitle;

  /// No description provided for @editCompanyExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit company expense'**
  String get editCompanyExpenseTitle;

  /// No description provided for @companyExpenseCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get companyExpenseCategoryLabel;

  /// No description provided for @companyExpenseCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Category is required.'**
  String get companyExpenseCategoryRequired;

  /// No description provided for @companyExpenseAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get companyExpenseAmountLabel;

  /// No description provided for @companyExpenseDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get companyExpenseDateLabel;

  /// No description provided for @companyExpenseReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference number'**
  String get companyExpenseReferenceLabel;

  /// No description provided for @companyExpenseNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get companyExpenseNotesLabel;

  /// No description provided for @companyExpenseAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount greater than zero.'**
  String get companyExpenseAmountInvalid;

  /// No description provided for @searchCompanyExpensesHint.
  ///
  /// In en, this message translates to:
  /// **'Search category, amount, reference, or notes'**
  String get searchCompanyExpensesHint;

  /// No description provided for @includeVoidedCompanyExpenses.
  ///
  /// In en, this message translates to:
  /// **'Show voided'**
  String get includeVoidedCompanyExpenses;

  /// No description provided for @noCompanyExpensesFound.
  ///
  /// In en, this message translates to:
  /// **'No company expenses found.'**
  String get noCompanyExpensesFound;

  /// No description provided for @noCompanyExpensesMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No company expenses match the current search.'**
  String get noCompanyExpensesMatchFilters;

  /// No description provided for @companyExpenseVoidedStatus.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get companyExpenseVoidedStatus;

  /// No description provided for @companyExpenseActiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get companyExpenseActiveStatus;

  /// No description provided for @voidCompanyExpenseButton.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get voidCompanyExpenseButton;

  /// No description provided for @voidCompanyExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Void company expense'**
  String get voidCompanyExpenseTitle;

  /// No description provided for @voidCompanyExpenseMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to void this expense? It will remain in the history as voided.'**
  String get voidCompanyExpenseMessage;

  /// No description provided for @voidReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Void reason'**
  String get voidReasonLabel;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @companyExpenseCategoryLine.
  ///
  /// In en, this message translates to:
  /// **'Category: {categoryName}'**
  String companyExpenseCategoryLine(String categoryName);

  /// No description provided for @companyExpenseAmountLine.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount}'**
  String companyExpenseAmountLine(String amount);

  /// No description provided for @companyExpenseDateLine.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String companyExpenseDateLine(String date);

  /// No description provided for @companyExpenseReferenceLine.
  ///
  /// In en, this message translates to:
  /// **'Reference: {reference}'**
  String companyExpenseReferenceLine(String reference);

  /// No description provided for @companyExpenseCategoryVehicleMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Vehicle maintenance'**
  String get companyExpenseCategoryVehicleMaintenance;

  /// No description provided for @companyExpenseCategorySpareParts.
  ///
  /// In en, this message translates to:
  /// **'Spare parts'**
  String get companyExpenseCategorySpareParts;

  /// No description provided for @companyExpenseCategoryTires.
  ///
  /// In en, this message translates to:
  /// **'Tires'**
  String get companyExpenseCategoryTires;

  /// No description provided for @companyExpenseCategoryOilsAndFluids.
  ///
  /// In en, this message translates to:
  /// **'Oils and fluids'**
  String get companyExpenseCategoryOilsAndFluids;

  /// No description provided for @companyExpenseCategoryLicensesAndRenewals.
  ///
  /// In en, this message translates to:
  /// **'Licenses and renewals'**
  String get companyExpenseCategoryLicensesAndRenewals;

  /// No description provided for @companyExpenseCategoryOfficeExpenses.
  ///
  /// In en, this message translates to:
  /// **'Office expenses'**
  String get companyExpenseCategoryOfficeExpenses;

  /// No description provided for @companyExpenseCategoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get companyExpenseCategoryRent;

  /// No description provided for @companyExpenseCategorySalaries.
  ///
  /// In en, this message translates to:
  /// **'Salaries'**
  String get companyExpenseCategorySalaries;

  /// No description provided for @companyExpenseCategoryAdminCosts.
  ///
  /// In en, this message translates to:
  /// **'Admin costs'**
  String get companyExpenseCategoryAdminCosts;

  /// No description provided for @companyExpenseCategoryFines.
  ///
  /// In en, this message translates to:
  /// **'Fines'**
  String get companyExpenseCategoryFines;

  /// No description provided for @companyExpenseCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get companyExpenseCategoryOther;

  /// No description provided for @failureUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error occurred.'**
  String get failureUnexpectedError;

  /// No description provided for @failureServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error occurred.'**
  String get failureServerError;

  /// No description provided for @failureValidationCompanyIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Company id is required.'**
  String get failureValidationCompanyIdRequired;

  /// No description provided for @failureValidationCompanyContextRequired.
  ///
  /// In en, this message translates to:
  /// **'Company context is required.'**
  String get failureValidationCompanyContextRequired;

  /// No description provided for @failureCompanyNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Selected company is not available for the current user.'**
  String get failureCompanyNotAvailable;

  /// No description provided for @failurePermissionCompanyUsersView.
  ///
  /// In en, this message translates to:
  /// **'This role cannot view company users.'**
  String get failurePermissionCompanyUsersView;

  /// No description provided for @failurePermissionCustomersView.
  ///
  /// In en, this message translates to:
  /// **'Customers access is not allowed.'**
  String get failurePermissionCustomersView;

  /// No description provided for @failurePermissionCustomersManagement.
  ///
  /// In en, this message translates to:
  /// **'Customers management is not allowed.'**
  String get failurePermissionCustomersManagement;

  /// No description provided for @failureValidationCustomerIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer id is required.'**
  String get failureValidationCustomerIdRequired;

  /// No description provided for @failureValidationCustomerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer name is required.'**
  String get failureValidationCustomerNameRequired;

  /// No description provided for @failureValidationCreditLimitNegative.
  ///
  /// In en, this message translates to:
  /// **'Credit limit cannot be negative.'**
  String get failureValidationCreditLimitNegative;

  /// No description provided for @failurePermissionDriversView.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to view drivers.'**
  String get failurePermissionDriversView;

  /// No description provided for @failurePermissionDriversManagement.
  ///
  /// In en, this message translates to:
  /// **'Drivers management is not allowed.'**
  String get failurePermissionDriversManagement;

  /// No description provided for @failureValidationDriverIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Driver id is required.'**
  String get failureValidationDriverIdRequired;

  /// No description provided for @failureValidationDriverNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Driver name is required.'**
  String get failureValidationDriverNameRequired;

  /// No description provided for @failurePermissionFleetManagement.
  ///
  /// In en, this message translates to:
  /// **'Fleet management is not allowed.'**
  String get failurePermissionFleetManagement;

  /// No description provided for @failurePermissionFleetView.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to view fleet.'**
  String get failurePermissionFleetView;

  /// No description provided for @failureValidationFleetPlateRequired.
  ///
  /// In en, this message translates to:
  /// **'Plate number is required.'**
  String get failureValidationFleetPlateRequired;

  /// No description provided for @failureValidationFleetFuelConsumptionNegative.
  ///
  /// In en, this message translates to:
  /// **'Expected fuel consumption cannot be negative.'**
  String get failureValidationFleetFuelConsumptionNegative;

  /// No description provided for @failurePermissionRoutesManagement.
  ///
  /// In en, this message translates to:
  /// **'Routes management is not allowed.'**
  String get failurePermissionRoutesManagement;

  /// No description provided for @failurePermissionRoutesView.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to view routes.'**
  String get failurePermissionRoutesView;

  /// No description provided for @failureValidationRouteLoadingLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Loading location is required.'**
  String get failureValidationRouteLoadingLocationRequired;

  /// No description provided for @failureValidationRouteUnloadingLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Unloading location is required.'**
  String get failureValidationRouteUnloadingLocationRequired;

  /// No description provided for @failureValidationRouteFreightPriceNegative.
  ///
  /// In en, this message translates to:
  /// **'Default freight price cannot be negative.'**
  String get failureValidationRouteFreightPriceNegative;

  /// No description provided for @failureValidationTripIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Trip id is required.'**
  String get failureValidationTripIdRequired;

  /// No description provided for @failurePermissionTripExpensesView.
  ///
  /// In en, this message translates to:
  /// **'Trip expenses access is not allowed.'**
  String get failurePermissionTripExpensesView;

  /// No description provided for @failurePermissionTripExpensesManagement.
  ///
  /// In en, this message translates to:
  /// **'Trip expenses management is not allowed.'**
  String get failurePermissionTripExpensesManagement;

  /// No description provided for @failureValidationTripExpenseIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Trip expense id is required.'**
  String get failureValidationTripExpenseIdRequired;

  /// No description provided for @failureValidationTripExpenseTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Expense type is required.'**
  String get failureValidationTripExpenseTypeRequired;

  /// No description provided for @failureValidationTripExpenseNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Expense name is required.'**
  String get failureValidationTripExpenseNameRequired;

  /// No description provided for @failureValidationTripExpenseAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Expense amount must be greater than zero.'**
  String get failureValidationTripExpenseAmountPositive;

  /// No description provided for @failurePermissionDriverFinanceView.
  ///
  /// In en, this message translates to:
  /// **'Driver finance access is not allowed.'**
  String get failurePermissionDriverFinanceView;

  /// No description provided for @failurePermissionDriverFinanceManagement.
  ///
  /// In en, this message translates to:
  /// **'Driver finance management is not allowed.'**
  String get failurePermissionDriverFinanceManagement;

  /// No description provided for @failureValidationDriverFinanceAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Driver financial movement amount must be greater than zero.'**
  String get failureValidationDriverFinanceAmountPositive;

  /// No description provided for @failurePermissionCompanyExpensesView.
  ///
  /// In en, this message translates to:
  /// **'Company expenses access is not allowed.'**
  String get failurePermissionCompanyExpensesView;

  /// No description provided for @failurePermissionCompanyExpensesManagement.
  ///
  /// In en, this message translates to:
  /// **'Company expenses management is not allowed.'**
  String get failurePermissionCompanyExpensesManagement;

  /// No description provided for @failureValidationCompanyExpenseIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Company expense id is required.'**
  String get failureValidationCompanyExpenseIdRequired;

  /// No description provided for @failureValidationCompanyExpenseCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Company expense category is required.'**
  String get failureValidationCompanyExpenseCategoryRequired;

  /// No description provided for @failureValidationCompanyExpenseAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Company expense amount must be greater than zero.'**
  String get failureValidationCompanyExpenseAmountPositive;

  /// No description provided for @failureValidationAuditEntityIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Audit entity id is required.'**
  String get failureValidationAuditEntityIdRequired;

  /// No description provided for @failureValidationAuditDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Audit description is required.'**
  String get failureValidationAuditDescriptionRequired;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @profileDetailsNotSetYet.
  ///
  /// In en, this message translates to:
  /// **'Profile details not set yet'**
  String get profileDetailsNotSetYet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
