import 'package:common_locale_data/ar.dart';
import 'package:common_locale_data/en.dart';
import 'package:flutter/widgets.dart';

import '../../domain/value_objects/company_timezone.dart';

final class CompanyTimezoneDisplayOption {
  final CompanyTimezone timezone;
  final String localizedName;
  final String englishName;
  final String arabicName;

  const CompanyTimezoneDisplayOption({
    required this.timezone,
    required this.localizedName,
    required this.englishName,
    required this.arabicName,
  });

  String get value => timezone.value;

  String get displayLabel =>
      localizedName == value ? value : '$localizedName ($value)';

  bool matches(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final searchableIana = value
        .replaceAll('/', ' ')
        .replaceAll('_', ' ')
        .toLowerCase();
    final searchIndex = [
      value.toLowerCase(),
      searchableIana,
      localizedName.toLowerCase(),
      englishName.toLowerCase(),
      arabicName.toLowerCase(),
    ].join(' ');

    return searchIndex.contains(query);
  }
}

abstract final class CompanyTimezoneDisplayResolver {
  static final CommonLocaleDataEn _english = CommonLocaleDataEn();
  static final CommonLocaleDataAr _arabic = CommonLocaleDataAr();

  static CompanyTimezoneDisplayOption resolve(
    CompanyTimezone timezone,
    Locale locale,
  ) {
    final englishName = _resolveEnglishName(timezone.value);
    final arabicName = _resolveArabicName(timezone.value);
    final localizedName = locale.languageCode == 'ar'
        ? arabicName
        : englishName;

    return CompanyTimezoneDisplayOption(
      timezone: timezone,
      localizedName: localizedName,
      englishName: englishName,
      arabicName: arabicName,
    );
  }

  static List<CompanyTimezoneDisplayOption> resolveAll(
    Iterable<CompanyTimezone> timezones,
    Locale locale,
  ) {
    final options = timezones
        .map((timezone) => resolve(timezone, locale))
        .toList(growable: false);
    options.sort(
      (left, right) => left.localizedName.toLowerCase().compareTo(
        right.localizedName.toLowerCase(),
      ),
    );
    return List.unmodifiable(options);
  }

  static String _resolveEnglishName(String timezoneId) {
    final exemplarCity = _english.timeZones
        .get(timezoneId.toLowerCase())
        ?.exemplarCity;
    return _resolvedName(exemplarCity, timezoneId);
  }

  static String _resolveArabicName(String timezoneId) {
    final exemplarCity = _arabic.timeZones
        .get(timezoneId.toLowerCase())
        ?.exemplarCity;
    return _resolvedName(exemplarCity, timezoneId);
  }

  static String _resolvedName(String? exemplarCity, String timezoneId) {
    final normalizedCity = exemplarCity?.trim();
    if (normalizedCity != null && normalizedCity.isNotEmpty) {
      return normalizedCity;
    }

    final segments = timezoneId.split('/');
    final fallback = segments.isEmpty ? timezoneId : segments.last;
    return fallback.replaceAll('_', ' ');
  }
}
