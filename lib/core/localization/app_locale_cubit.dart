import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppLocaleCubit extends Cubit<Locale> {
  AppLocaleCubit() : super(const Locale('en'));

  static const Locale english = Locale('en');
  static const Locale arabic = Locale('ar');

  bool get isArabic => state.languageCode == arabic.languageCode;

  void toggleLanguage() {
    emit(isArabic ? english : arabic);
  }

  void setLocale(Locale locale) {
    if (locale.languageCode == state.languageCode) return;

    emit(locale);
  }
}
