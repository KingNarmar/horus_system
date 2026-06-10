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
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
