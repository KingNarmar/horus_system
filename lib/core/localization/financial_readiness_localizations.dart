import 'package:flutter/widgets.dart';

final class FinancialReadinessLocalizations {
  final String configurationRequired;

  const FinancialReadinessLocalizations._({
    required this.configurationRequired,
  });

  factory FinancialReadinessLocalizations.forLocale(Locale locale) {
    return locale.languageCode == 'ar' ? _arabic : _english;
  }

  static const _english = FinancialReadinessLocalizations._(
    configurationRequired:
        'Configure the company financial settings before using this module.',
  );

  static const _arabic = FinancialReadinessLocalizations._(
    configurationRequired:
        'أكمل الإعدادات المالية للشركة قبل استخدام هذه الوحدة.',
  );
}

extension FinancialReadinessLocalizationsBuildContextX on BuildContext {
  FinancialReadinessLocalizations get financialReadinessL10n =>
      FinancialReadinessLocalizations.forLocale(Localizations.localeOf(this));
}
