import 'package:flutter/widgets.dart';

final class ExpenseTypesLocalizations {
  final Map<String, String> _values;

  const ExpenseTypesLocalizations._(this._values);

  factory ExpenseTypesLocalizations.forLocale(Locale locale) {
    return locale.languageCode == 'ar'
        ? const ExpenseTypesLocalizations._(_ar)
        : const ExpenseTypesLocalizations._(_en);
  }

  String _value(String key) => _values[key]!;

  String get title => _value('title');
  String get description => _value('description');
  String get nameLabel => _value('nameLabel');
  String get status => _value('status');
  String get active => _value('active');
  String get inactive => _value('inactive');
  String get all => _value('all');
  String get retry => _value('retry');
  String get loading => _value('loading');
  String get noTypes => _value('noTypes');
  String get noFilteredTypes => _value('noFilteredTypes');
  String get permissionViewFailure => _value('permissionViewFailure');
  String get genericFailure => _value('genericFailure');

  static const Map<String, String> _en = {
    'title': 'Expense types',
    'description':
        'View the canonical expense type catalog used by trip expenses and the financial ledger.',
    'nameLabel': 'Name',
    'status': 'Status',
    'active': 'Active',
    'inactive': 'Inactive',
    'all': 'All',
    'retry': 'Retry',
    'loading': 'Loading expense types...',
    'noTypes': 'No expense types are available.',
    'noFilteredTypes': 'No expense types match this status filter.',
    'permissionViewFailure': 'This role cannot view expense types.',
    'genericFailure': 'Expense types could not be loaded.',
  };

  static const Map<String, String> _ar = {
    'title': 'أنواع المصروفات',
    'description':
        'عرض دليل أنواع المصروفات المعتمد المستخدم في مصروفات الرحلات ودفتر الأستاذ المالي.',
    'nameLabel': 'الاسم',
    'status': 'الحالة',
    'active': 'نشط',
    'inactive': 'غير نشط',
    'all': 'الكل',
    'retry': 'إعادة المحاولة',
    'loading': 'جاري تحميل أنواع المصروفات...',
    'noTypes': 'لا توجد أنواع مصروفات متاحة.',
    'noFilteredTypes': 'لا توجد أنواع مصروفات مطابقة لفلتر الحالة الحالي.',
    'permissionViewFailure': 'هذا الدور غير مسموح له بعرض أنواع المصروفات.',
    'genericFailure': 'تعذر تحميل أنواع المصروفات.',
  };
}

extension ExpenseTypesLocalizationsContextX on BuildContext {
  ExpenseTypesLocalizations get expenseTypesL10n =>
      ExpenseTypesLocalizations.forLocale(Localizations.localeOf(this));
}
