import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  String get appTitle;
  String get appSubtitle;
  String get launchDescription;
  String get architectureBadge;
  String get appShellDashboardLabel;
  String get appShellDashboardDescription;
  String get appShellCustomersLabel;
  String get appShellCustomersDescription;
  String get appShellDriversLabel;
  String get appShellDriversDescription;
  String get appShellFleetLabel;
  String get appShellFleetDescription;
  String get appShellRoutesLabel;
  String get appShellRoutesDescription;
  String get appShellTripsLabel;
  String get appShellTripsDescription;
  String get appShellExpensesLabel;
  String get appShellExpensesDescription;
  String get appShellInvoicesLabel;
  String get appShellInvoicesDescription;
  String get appShellReportsLabel;
  String get appShellReportsDescription;
  String get appShellSettingsLabel;
  String get appShellSettingsDescription;
  String get appShellMoreLabel;
  String get logout;
  String companyWithName(String companyName);
  String roleWithName(String roleName);
  String get companySettingsTitle;
  String get manageUsers;
  String get noPermissionManageUsers;
  String get switchToArabic;
  String get switchToEnglish;
  String get adaptiveAccessNotice;
  String get roleOwner;
  String get roleAdmin;
  String get roleOperations;
  String get roleAccountant;
  String get roleViewer;
  String get roleDriver;
  String get loginWelcomeTitle;
  String get loginSubtitle;
  String get emailLabel;
  String get passwordLabel;
  String get emailRequired;
  String get passwordRequired;
  String get loginButton;
  String get createNewAccountButton;
  String get createAccountTitle;
  String get registerTitle;
  String get registerSubtitle;
  String get fullNameLabel;
  String get fullNameRequired;
  String get phoneNumberLabel;
  String get phoneNumberRequired;
  String get passwordMinLength;
  String get createAccountButton;
  String get checkYourEmailTitle;
  String emailConfirmationMessage(String email);
  String get backToLoginButton;
  String get createCompanyTitle;
  String get createCompanyFormTitle;
  String get createCompanySubtitle;
  String get companyNameLabel;
  String get companyNameRequired;
  String get businessTypeLabel;
  String get phoneLabel;
  String get countryLabel;
  String get cityLabel;
  String get createCompanyButton;
  String get companyContextLoadedTitle;
  String get companyContextNextStep;
  String get currentCompanyContextRequired;
  String get companyUsersTitle;
  String get inviteButton;
  String get noCompanyUsersFound;
  String get inviteFlowComingSoon;
  String get activeStatus;
  String get inactiveStatus;
  String roleLine(String roleName);
  String statusLine(String status);
  String get incompleteProfileMessage;
  String get customersTitle => '\u0627\u0644\u0639\u0645\u0644\u0627\u0621';
  String get addCustomerButton => '\u0625\u0636\u0627\u0641\u0629 \u0639\u0645\u064a\u0644';
  String get addCustomerTitle => '\u0625\u0636\u0627\u0641\u0629 \u0639\u0645\u064a\u0644';
  String get editCustomerTitle => '\u062a\u0639\u062f\u064a\u0644 \u0639\u0645\u064a\u0644';
  String get editCustomerButton => '\u062a\u0639\u062f\u064a\u0644';
  String get deactivateCustomerButton => '\u0625\u064a\u0642\u0627\u0641';
  String get customerNameLabel => '\u0627\u0633\u0645 \u0627\u0644\u0639\u0645\u064a\u0644';
  String get customerNameRequired => '\u0627\u0633\u0645 \u0627\u0644\u0639\u0645\u064a\u0644 \u0645\u0637\u0644\u0648\u0628.';
  String get contactPersonLabel => '\u0627\u0644\u0634\u062e\u0635 \u0627\u0644\u0645\u0633\u0624\u0648\u0644';
  String get taxRegistrationNumberLabel => '\u0627\u0644\u0631\u0642\u0645 \u0627\u0644\u0636\u0631\u064a\u0628\u064a / TRN';
  String get addressLabel => '\u0627\u0644\u0639\u0646\u0648\u0627\u0646';
  String get creditLimitLabel => '\u062d\u062f \u0627\u0644\u0627\u0626\u062a\u0645\u0627\u0646';
  String get creditLimitInvalid => '\u062d\u062f \u0627\u0644\u0627\u0626\u062a\u0645\u0627\u0646 \u064a\u062c\u0628 \u0623\u0646 \u064a\u0643\u0648\u0646 \u0631\u0642\u0645\u064b\u0627 \u0635\u062d\u064a\u062d\u064b\u0627 \u063a\u064a\u0631 \u0633\u0627\u0644\u0628.';
  String get saveButton => '\u062d\u0641\u0638';
  String get cancelButton => '\u0625\u0644\u063a\u0627\u0621';
  String get retryButton => '\u0625\u0639\u0627\u062f\u0629 \u0627\u0644\u0645\u062d\u0627\u0648\u0644\u0629';
  String get noCustomersFound => '\u0644\u0627 \u064a\u0648\u062c\u062f \u0639\u0645\u0644\u0627\u0621.';
  String get customerNameHeader => '\u0627\u0644\u0639\u0645\u064a\u0644';
  String get contactHeader => '\u0627\u0644\u062a\u0648\u0627\u0635\u0644';
  String get statusHeader => '\u0627\u0644\u062d\u0627\u0644\u0629';
  String get actionsHeader => '\u0627\u0644\u0625\u062c\u0631\u0627\u0621\u0627\u062a';
  String contactPersonLine(String contactPerson) => '\u0627\u0644\u0645\u0633\u0624\u0648\u0644: $contactPerson';
  String phoneLine(String phone) => '\u0627\u0644\u0647\u0627\u062a\u0641: $phone';
  String emailLine(String email) => '\u0627\u0644\u0628\u0631\u064a\u062f: $email';
  String cityLine(String city) => '\u0627\u0644\u0645\u062f\u064a\u0646\u0629: $city';
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
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale".',
  );
}
