import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AppLocaleStorage {
  Future<Locale?> loadLocale();

  Future<void> saveLocale(Locale locale);
}

class SharedPreferencesAppLocaleStorage implements AppLocaleStorage {
  static const String _localeKey = 'app_locale';
  static const Set<String> _supportedLanguageCodes = {'en', 'ar'};

  const SharedPreferencesAppLocaleStorage();

  @override
  Future<Locale?> loadLocale() async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = preferences.getString(_localeKey);

    if (languageCode == null ||
        !_supportedLanguageCodes.contains(languageCode)) {
      return null;
    }

    return Locale(languageCode);
  }

  @override
  Future<void> saveLocale(Locale locale) async {
    if (!_supportedLanguageCodes.contains(locale.languageCode)) return;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localeKey, locale.languageCode);
  }
}
