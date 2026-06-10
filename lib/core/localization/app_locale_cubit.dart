import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_locale_storage.dart';

class AppLocaleCubit extends Cubit<Locale> {
  final AppLocaleStorage _storage;

  AppLocaleCubit({required AppLocaleStorage storage})
      : _storage = storage,
        super(english) {
    unawaited(_loadSavedLocale());
  }

  static const Locale english = Locale('en');
  static const Locale arabic = Locale('ar');
  static const Set<String> supportedLanguageCodes = {'en', 'ar'};

  bool get isArabic => state.languageCode == arabic.languageCode;

  void toggleLanguage() {
    setLocale(isArabic ? english : arabic);
  }

  void setLocale(Locale locale) {
    if (!supportedLanguageCodes.contains(locale.languageCode)) return;
    if (locale.languageCode == state.languageCode) return;

    emit(locale);
    unawaited(_storage.saveLocale(locale));
  }

  Future<void> _loadSavedLocale() async {
    final savedLocale = await _storage.loadLocale();

    if (savedLocale == null || isClosed) return;
    if (!supportedLanguageCodes.contains(savedLocale.languageCode)) return;
    if (savedLocale.languageCode == state.languageCode) return;

    emit(savedLocale);
  }
}
