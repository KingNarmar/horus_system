import 'package:common_locale_data/ar.dart';
import 'package:common_locale_data/en.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/domain/value_objects/currency_code.dart';

final class CompanyCurrencyDisplayOption {
  final CurrencyCode currencyCode;
  final String localizedName;
  final String englishName;
  final String arabicName;

  const CompanyCurrencyDisplayOption({
    required this.currencyCode,
    required this.localizedName,
    required this.englishName,
    required this.arabicName,
  });

  String get value => currencyCode.value;

  String get displayLabel =>
      localizedName == value ? value : '$value — $localizedName';

  bool matches(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final searchIndex = [
      value.toLowerCase(),
      localizedName.toLowerCase(),
      englishName.toLowerCase(),
      arabicName.toLowerCase(),
    ].join(' ');

    return searchIndex.contains(query);
  }
}

abstract final class CompanyCurrencyDisplayResolver {
  static final CommonLocaleDataEn _english = CommonLocaleDataEn();
  static final CommonLocaleDataAr _arabic = CommonLocaleDataAr();

  static CompanyCurrencyDisplayOption resolve(
    CurrencyCode currencyCode,
    Locale locale,
  ) {
    final lookupCode = currencyCode.value.toLowerCase();
    final englishName = _resolveName(
      _english.currencies[lookupCode]?.displayName,
      currencyCode.value,
    );
    final arabicName = _resolveName(
      _arabic.currencies[lookupCode]?.displayName,
      englishName,
    );
    final localizedName = locale.languageCode == 'ar'
        ? arabicName
        : englishName;

    return CompanyCurrencyDisplayOption(
      currencyCode: currencyCode,
      localizedName: localizedName,
      englishName: englishName,
      arabicName: arabicName,
    );
  }

  static List<CompanyCurrencyDisplayOption> resolveAll(
    Locale locale, {
    String? includeCurrencyCode,
  }) {
    final rawCodes = <String>{
      ..._english.currencies.currencies.keys,
      ..._arabic.currencies.currencies.keys,
    };
    final includedCurrency = includeCurrencyCode == null
        ? null
        : CurrencyCode.tryParse(includeCurrencyCode);
    if (includedCurrency != null) {
      rawCodes.add(includedCurrency.value);
    }

    final uniqueCurrencies = <String, CurrencyCode>{};
    for (final rawCode in rawCodes) {
      final currencyCode = CurrencyCode.tryParse(rawCode);
      if (currencyCode == null) continue;
      uniqueCurrencies[currencyCode.value] = currencyCode;
    }

    final options = uniqueCurrencies.values
        .map((currencyCode) => resolve(currencyCode, locale))
        .toList(growable: false);
    options.sort((left, right) {
      final nameComparison = left.localizedName.toLowerCase().compareTo(
        right.localizedName.toLowerCase(),
      );
      if (nameComparison != 0) return nameComparison;
      return left.value.compareTo(right.value);
    });
    return List.unmodifiable(options);
  }

  static String _resolveName(String? rawName, String fallback) {
    final normalized = rawName?.trim();
    if (normalized == null || normalized.isEmpty) return fallback;
    return normalized;
  }
}
