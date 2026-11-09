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
  String get creationLimitReached => _value('creationLimitReached');
  String get creationRequestConflict => _value('creationRequestConflict');
  String get creationRetryUnavailable => _value('creationRetryUnavailable');

  static const _en = <String, String>{
    'creationLimitReached':
        'Your normal company-creation allowance is already used. You can still join other companies by invitation.',
    'creationRequestConflict':
        'This company creation request was changed. Review the details and try again.',
    'creationRetryUnavailable':
        'The original creation cannot be reopened with this request. Use company switching or contact support.',
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
    'creationLimitReached':
        'استخدمت حق إنشاء الشركة المتاح لحسابك. ما زال بإمكانك الانضمام لشركات أخرى بالدعوة.',
    'creationRequestConflict':
        'تم تغيير بيانات طلب إنشاء الشركة. راجع البيانات وحاول مجددًا.',
    'creationRetryUnavailable':
        'لا يمكن إعادة فتح الشركة من طلب الإنشاء السابق. استخدم تبديل الشركات أو تواصل مع الدعم.',
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
