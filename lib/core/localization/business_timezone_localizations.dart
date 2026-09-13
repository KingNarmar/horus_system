import 'package:flutter/widgets.dart';

final class BusinessTimezoneLocalizations {
  final String configurationRequired;

  const BusinessTimezoneLocalizations._({
    required this.configurationRequired,
  });

  factory BusinessTimezoneLocalizations.forLocale(Locale locale) {
    return locale.languageCode == 'ar' ? _arabic : _english;
  }

  static const _english = BusinessTimezoneLocalizations._(
    configurationRequired:
        'Configure the company business timezone before using this module.',
  );

  static const _arabic = BusinessTimezoneLocalizations._(
    configurationRequired:
        'اضبط المنطقة الزمنية للعمل بالشركة قبل استخدام هذه الوحدة.',
  );
}

extension BusinessTimezoneLocalizationsBuildContextX on BuildContext {
  BusinessTimezoneLocalizations get businessTimezoneL10n =>
      BusinessTimezoneLocalizations.forLocale(Localizations.localeOf(this));
}
