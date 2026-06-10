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
