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
}
