import 'package:flutter/widgets.dart';

final class CompanyFinancialSettingsLocalizations {
  final Map<String, String> _values;

  const CompanyFinancialSettingsLocalizations._(this._values);

  factory CompanyFinancialSettingsLocalizations.forLocale(Locale locale) {
    return locale.languageCode == 'ar'
        ? const CompanyFinancialSettingsLocalizations._(_ar)
        : const CompanyFinancialSettingsLocalizations._(_en);
  }

  String _value(String key) => _values[key]!;

  String get title => _value('title');
  String get description => _value('description');
  String get ready => _value('ready');
  String get configurationRequired => _value('configurationRequired');
  String get invalidConfiguration => _value('invalidConfiguration');
  String get baseCurrencyLabel => _value('baseCurrencyLabel');
  String get baseCurrencyHint => _value('baseCurrencyHint');
  String get fractionDigitsLabel => _value('fractionDigitsLabel');
  String get save => _value('save');
  String get saving => _value('saving');
  String get saved => _value('saved');
  String get lockNotice => _value('lockNotice');
  String get initialSetupNotice => _value('initialSetupNotice');
  String get permissionNotice => _value('permissionNotice');
  String get invalidCurrency => _value('invalidCurrency');
  String get invalidFractionDigits => _value('invalidFractionDigits');
  String get lockedFailure => _value('lockedFailure');
  String get historyMismatchFailure => _value('historyMismatchFailure');
  String get permissionFailure => _value('permissionFailure');
  String get notFoundFailure => _value('notFoundFailure');
  String get authFailure => _value('authFailure');
  String get genericFailure => _value('genericFailure');

  String currentValue(String currency, int digits) => _value('currentValue')
      .replaceFirst('{currency}', currency)
      .replaceFirst('{digits}', '$digits');

  static const Map<String, String> _en = {
    'title': 'Financial configuration',
    'description':
        'Defines the company base currency and money precision used by financial modules.',
    'ready': 'Financial configuration is ready.',
    'configurationRequired':
        'Configure the base currency before using financial modules.',
    'invalidConfiguration':
        'The current financial configuration is invalid and must be corrected.',
    'baseCurrencyLabel': 'Base currency code',
    'baseCurrencyHint': 'Enter a 3-letter code, for example AED',
    'fractionDigitsLabel': 'Fraction digits',
    'save': 'Save financial configuration',
    'saving': 'Saving...',
    'saved': 'Financial configuration updated.',
    'lockNotice':
        'After currency-bound financial data exists, changing the base currency or precision is blocked to protect historical values.',
    'initialSetupNotice':
        'For an existing company, the first configuration applies to its existing financial history. It must match any currency already recorded on historical invoices or payments.',
    'permissionNotice':
        'Only an Owner or Admin can change the financial configuration.',
    'invalidCurrency': 'Enter a valid 3-letter currency code.',
    'invalidFractionDigits': 'Select a valid number of fraction digits.',
    'lockedFailure':
        'The base currency cannot be changed because currency-bound financial data already exists.',
    'historyMismatchFailure':
        'The selected base currency conflicts with currency already recorded in historical financial data.',
    'permissionFailure':
        'Only an Owner or Admin can change the financial configuration.',
    'notFoundFailure': 'The current company could not be found.',
    'authFailure': 'Sign in again to complete this company action.',
    'genericFailure': 'The financial configuration could not be updated.',
    'currentValue': 'Current base currency: {currency} • {digits} fraction digits',
  };

  static const Map<String, String> _ar = {
    'title': 'الإعدادات المالية',
    'description':
        'تحدد العملة الأساسية للشركة ودقة المبالغ المستخدمة في الوحدات المالية.',
    'ready': 'الإعدادات المالية جاهزة.',
    'configurationRequired':
        'حدد العملة الأساسية قبل استخدام الوحدات المالية.',
    'invalidConfiguration':
        'الإعدادات المالية الحالية غير صحيحة ويجب تصحيحها.',
    'baseCurrencyLabel': 'رمز العملة الأساسية',
    'baseCurrencyHint': 'أدخل رمزًا من 3 أحرف، مثل AED',
    'fractionDigitsLabel': 'عدد الخانات العشرية',
    'save': 'حفظ الإعدادات المالية',
    'saving': 'جاري الحفظ...',
    'saved': 'تم تحديث الإعدادات المالية.',
    'lockNotice':
        'بعد وجود بيانات مالية مرتبطة بالعملة، يُمنع تغيير العملة الأساسية أو دقتها لحماية القيم التاريخية.',
    'initialSetupNotice':
        'للشركة القائمة، أول إعداد للعملة سيطبق على تاريخها المالي الموجود، ويجب أن يطابق أي عملة مسجلة بالفعل في الفواتير أو المدفوعات التاريخية.',
    'permissionNotice':
        'يمكن للمالك أو المسؤول فقط تغيير الإعدادات المالية.',
    'invalidCurrency': 'أدخل رمز عملة صحيحًا من 3 أحرف.',
    'invalidFractionDigits': 'اختر عددًا صحيحًا للخانات العشرية.',
    'lockedFailure':
        'لا يمكن تغيير العملة الأساسية لوجود بيانات مالية مرتبطة بها بالفعل.',
    'historyMismatchFailure':
        'العملة الأساسية المختارة تتعارض مع عملة مسجلة بالفعل في البيانات المالية التاريخية.',
    'permissionFailure':
        'يمكن للمالك أو المسؤول فقط تغيير الإعدادات المالية.',
    'notFoundFailure': 'تعذر العثور على الشركة الحالية.',
    'authFailure': 'سجل الدخول مرة أخرى لإكمال هذا الإجراء.',
    'genericFailure': 'تعذر تحديث الإعدادات المالية.',
    'currentValue': 'العملة الأساسية الحالية: {currency} • {digits} خانات عشرية',
  };
}

extension CompanyFinancialSettingsLocalizationsContextX on BuildContext {
  CompanyFinancialSettingsLocalizations get companyFinancialSettingsL10n =>
      CompanyFinancialSettingsLocalizations.forLocale(
        Localizations.localeOf(this),
      );
}
