import 'package:flutter/widgets.dart';

/// Dedicated EN/AR messages for first-time company setup.
final class CompanyOnboardingLocalizations {
  final Map<String, String> _values;

  const CompanyOnboardingLocalizations._(this._values);

  factory CompanyOnboardingLocalizations.forLocale(Locale locale) =>
      locale.languageCode == 'ar'
          ? const CompanyOnboardingLocalizations._(_ar)
          : const CompanyOnboardingLocalizations._(_en);

  String _value(String key) => _values[key]!;

  String get financialSectionTitle => _value('financialSectionTitle');
  String get invoiceSectionTitle => _value('invoiceSectionTitle');
  String get currencyRequired => _value('currencyRequired');
  String get currencyInvalid => _value('currencyInvalid');
  String get fractionDigitsRequired => _value('fractionDigitsRequired');
  String get fractionDigitsInvalid => _value('fractionDigitsInvalid');
  String get invoicePrefixLabel => _value('invoicePrefixLabel');
  String get invoicePrefixHint => _value('invoicePrefixHint');
  String get invoicePrefixRequired => _value('invoicePrefixRequired');
  String get invoicePrefixInvalid => _value('invoicePrefixInvalid');

  static const _en = <String, String>{
    'financialSectionTitle': 'Financial configuration',
    'invoiceSectionTitle': 'Invoice numbering',
    'currencyRequired': 'Select a base currency.',
    'currencyInvalid': 'Select a valid base currency.',
    'fractionDigitsRequired': 'Select the currency fraction digits.',
    'fractionDigitsInvalid': 'Select valid currency fraction digits.',
    'invoicePrefixLabel': 'Invoice prefix',
    'invoicePrefixHint': 'Example: INV',
    'invoicePrefixRequired': 'Enter an invoice prefix.',
    'invoicePrefixInvalid':
        'The prefix must start with a letter and contain only uppercase letters, digits or hyphens (maximum 16 characters).',
  };

  static const _ar = <String, String>{
    'financialSectionTitle': 'الإعدادات المالية',
    'invoiceSectionTitle': 'ترقيم الفواتير',
    'currencyRequired': 'اختر العملة الأساسية.',
    'currencyInvalid': 'اختر عملة أساسية صحيحة.',
    'fractionDigitsRequired': 'اختر عدد الخانات العشرية للعملة.',
    'fractionDigitsInvalid': 'اختر عدد خانات عشرية صحيحًا.',
    'invoicePrefixLabel': 'بادئة رقم الفاتورة',
    'invoicePrefixHint': 'مثال: INV',
    'invoicePrefixRequired': 'اكتب بادئة رقم الفاتورة.',
    'invoicePrefixInvalid':
        'يجب أن تبدأ البادئة بحرف، وأن تحتوي على حروف إنجليزية كبيرة أو أرقام أو شرطات فقط (16 حرفًا كحد أقصى).',
  };
}

extension CompanyOnboardingLocalizationsX on BuildContext {
  CompanyOnboardingLocalizations get companyOnboardingL10n =>
      CompanyOnboardingLocalizations.forLocale(Localizations.localeOf(this));
}
