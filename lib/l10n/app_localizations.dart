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

  /// The application title.
  ///
  /// In en, this message translates to:
  /// **'H.O.R.U.S System'**
  String get appTitle;

  /// The application subtitle.
  ///
  /// In en, this message translates to:
  /// **'Heavy Operations & Route Unified System'**
  String get appSubtitle;

  /// Short description displayed on the launch page.
  ///
  /// In en, this message translates to:
  /// **'SaaS platform for heavy transport operations.'**
  String get launchDescription;

  /// Architecture rule badge displayed on the launch page.
  ///
  /// In en, this message translates to:
  /// **'Clean Architecture by the book • SOLID Principles'**
  String get architectureBadge;

  /// App shell dashboard destination label.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get appShellDashboardLabel;

  /// App shell dashboard destination description.
  ///
  /// In en, this message translates to:
  /// **'Live overview for company operations and finance.'**
  String get appShellDashboardDescription;

  /// App shell customers destination label.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get appShellCustomersLabel;

  /// App shell customers destination description.
  ///
  /// In en, this message translates to:
  /// **'Manage customer master data and account activity.'**
  String get appShellCustomersDescription;

  /// App shell drivers destination label.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get appShellDriversLabel;

  /// App shell drivers destination description.
  ///
  /// In en, this message translates to:
  /// **'Manage drivers, status, and driver actions.'**
  String get appShellDriversDescription;

  /// App shell fleet destination label.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get appShellFleetLabel;

  /// App shell fleet destination description.
  ///
  /// In en, this message translates to:
  /// **'Manage tractor heads, trailers, and availability.'**
  String get appShellFleetDescription;

  /// App shell routes destination label.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get appShellRoutesLabel;

  /// App shell routes destination description.
  ///
  /// In en, this message translates to:
  /// **'Manage loading points, delivery points, and lanes.'**
  String get appShellRoutesDescription;

  /// App shell trips destination label.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get appShellTripsLabel;

  /// App shell trips destination description.
  ///
  /// In en, this message translates to:
  /// **'Create, track, and update trips.'**
  String get appShellTripsDescription;

  /// App shell expenses destination label.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get appShellExpensesLabel;

  /// App shell expenses destination description.
  ///
  /// In en, this message translates to:
  /// **'Track trip costs, fees, and financial movements.'**
  String get appShellExpensesDescription;

  /// App shell invoices destination label.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get appShellInvoicesLabel;

  /// App shell invoices destination description.
  ///
  /// In en, this message translates to:
  /// **'Create invoices, register payments, and track balances.'**
  String get appShellInvoicesDescription;

  /// App shell reports destination label.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get appShellReportsLabel;

  /// App shell reports destination description.
  ///
  /// In en, this message translates to:
  /// **'Review operational and financial reports.'**
  String get appShellReportsDescription;

  /// App shell settings destination label.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get appShellSettingsLabel;

  /// App shell settings destination description.
  ///
  /// In en, this message translates to:
  /// **'Manage company settings, users, roles, and access.'**
  String get appShellSettingsDescription;

  /// Mobile bottom navigation label for extra modules.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get appShellMoreLabel;

  /// Logout action label and tooltip.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Company name display line.
  ///
  /// In en, this message translates to:
  /// **'Company: {companyName}'**
  String companyWithName(String companyName);

  /// User role display line.
  ///
  /// In en, this message translates to:
  /// **'Role: {roleName}'**
  String roleWithName(String roleName);

  /// Company settings card title.
  ///
  /// In en, this message translates to:
  /// **'Company settings'**
  String get companySettingsTitle;

  /// Button label to open company users management.
  ///
  /// In en, this message translates to:
  /// **'Manage users'**
  String get manageUsers;

  /// Message shown when the current user cannot manage company users.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to manage users.'**
  String get noPermissionManageUsers;

  /// Language toggle label when the next language is Arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get switchToArabic;

  /// Language toggle label when the next language is English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get switchToEnglish;

  /// Notice explaining responsive access rule.
  ///
  /// In en, this message translates to:
  /// **'Same modules on every device. The screen layout changes, not the available actions.'**
  String get adaptiveAccessNotice;

  /// Company owner role label.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// Company admin role label.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// Company operations role label.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get roleOperations;

  /// Company accountant role label.
  ///
  /// In en, this message translates to:
  /// **'Accountant'**
  String get roleAccountant;

  /// Company viewer role label.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleViewer;

  /// Company driver role label.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleDriver;
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
