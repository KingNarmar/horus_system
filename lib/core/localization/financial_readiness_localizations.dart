import 'package:flutter/widgets.dart';

final class FinancialReadinessLocalizations {
  final String configurationRequired;
  final String currencyMismatch;

  const FinancialReadinessLocalizations._({
    required this.configurationRequired,
    required this.currencyMismatch,
  });

  factory FinancialReadinessLocalizations.forLocale(Locale locale) {
    return locale.languageCode == 'ar' ? _arabic : _english;
  }

  static const _english = FinancialReadinessLocalizations._(
    configurationRequired:
        'Configure the company financial settings before using this module.',
    currencyMismatch:
        'Financial data currency does not match the company currency.',
  );

  static const _arabic = FinancialReadinessLocalizations._(
    configurationRequired:
        'أكمل الإعدادات المالية للشركة قبل استخدام هذه الوحدة.',
    currencyMismatch: 'عملة البيانات المالية لا تطابق عملة الشركة.',
  );
}

extension FinancialReadinessLocalizationsBuildContextX on BuildContext {
  FinancialReadinessLocalizations get financialReadinessL10n =>
      FinancialReadinessLocalizations.forLocale(Localizations.localeOf(this));
}
