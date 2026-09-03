import 'package:flutter/widgets.dart';

final class CompanyTimezoneLocalizations {
  final Map<String, String> _values;

  const CompanyTimezoneLocalizations._(this._values);

  factory CompanyTimezoneLocalizations.forLocale(Locale locale) {
    return locale.languageCode == 'ar'
        ? const CompanyTimezoneLocalizations._(_ar)
        : const CompanyTimezoneLocalizations._(_en);
  }

  String _value(String key) => _values[key]!;

  String get title => _value('title');
  String get description => _value('description');
  String get label => _value('label');
  String get hint => _value('hint');
  String get required => _value('required');
  String get invalid => _value('invalid');
  String get loading => _value('loading');
  String get loadFailed => _value('loadFailed');
  String get save => _value('save');
  String get saving => _value('saving');
  String get retry => _value('retry');
  String get saved => _value('saved');
  String get permissionFailure => _value('permissionFailure');
  String get notFoundFailure => _value('notFoundFailure');
  String get authFailure => _value('authFailure');
  String get genericFailure => _value('genericFailure');
  String get notConfigured => _value('notConfigured');

  String currentValue(String timezone) =>
      _value('currentValue').replaceFirst('{timezone}', timezone);

  static const Map<String, String> _en = {
    'title': 'Business timezone',
    'description':
        'Used to determine the company business date and future date-based operational reporting.',
    'label': 'Timezone',
    'hint': 'Select the company business timezone',
    'required': 'Business timezone is required.',
    'invalid': 'Select a valid business timezone.',
    'loading': 'Loading timezones...',
    'loadFailed': 'Timezones could not be loaded.',
    'save': 'Save timezone',
    'saving': 'Saving...',
    'retry': 'Retry',
    'saved': 'Business timezone updated.',
    'permissionFailure':
        'Only an Owner or Admin can change the business timezone.',
    'notFoundFailure': 'The current company could not be found.',
    'authFailure': 'Sign in again to complete this company action.',
    'genericFailure': 'The business timezone action could not be completed.',
    'notConfigured': 'Not configured',
    'currentValue': 'Current timezone: {timezone}',
  };

  static const Map<String, String> _ar = {
    'title': 'المنطقة الزمنية للشركة',
    'description':
        'تُستخدم لتحديد تاريخ عمل الشركة ولدعم التقارير التشغيلية المعتمدة على التاريخ لاحقًا.',
    'label': 'المنطقة الزمنية',
    'hint': 'اختر المنطقة الزمنية الخاصة بعمل الشركة',
    'required': 'المنطقة الزمنية للشركة مطلوبة.',
    'invalid': 'اختر منطقة زمنية صحيحة.',
    'loading': 'جاري تحميل المناطق الزمنية...',
    'loadFailed': 'تعذر تحميل المناطق الزمنية.',
    'save': 'حفظ المنطقة الزمنية',
    'saving': 'جاري الحفظ...',
    'retry': 'إعادة المحاولة',
    'saved': 'تم تحديث المنطقة الزمنية للشركة.',
    'permissionFailure':
        'يمكن للمالك أو المسؤول فقط تغيير المنطقة الزمنية للشركة.',
    'notFoundFailure': 'تعذر العثور على الشركة الحالية.',
    'authFailure': 'سجل الدخول مرة أخرى لإكمال هذا الإجراء.',
    'genericFailure': 'تعذر إكمال إجراء المنطقة الزمنية للشركة.',
    'notConfigured': 'غير محددة',
    'currentValue': 'المنطقة الزمنية الحالية: {timezone}',
  };
}

extension CompanyTimezoneLocalizationsContextX on BuildContext {
  CompanyTimezoneLocalizations get companyTimezoneL10n =>
      CompanyTimezoneLocalizations.forLocale(Localizations.localeOf(this));
}
