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
  String get addType => _value('addType');
  String get editType => _value('editType');
  String get nameLabel => _value('nameLabel');
  String get nameHint => _value('nameHint');
  String get nameRequired => _value('nameRequired');
  String get save => _value('save');
  String get cancel => _value('cancel');
  String get saving => _value('saving');
  String get status => _value('status');
  String get active => _value('active');
  String get inactive => _value('inactive');
  String get all => _value('all');
  String get actions => _value('actions');
  String get edit => _value('edit');
  String get deactivate => _value('deactivate');
  String get reactivate => _value('reactivate');
  String get retry => _value('retry');
  String get loading => _value('loading');
  String get noTypes => _value('noTypes');
  String get noFilteredTypes => _value('noFilteredTypes');
  String get permissionViewFailure => _value('permissionViewFailure');
  String get permissionManageFailure => _value('permissionManageFailure');
  String get duplicateNameFailure => _value('duplicateNameFailure');
  String get notFoundFailure => _value('notFoundFailure');
  String get genericFailure => _value('genericFailure');
  String get createdSuccess => _value('createdSuccess');
  String get updatedSuccess => _value('updatedSuccess');
  String get deactivatedSuccess => _value('deactivatedSuccess');
  String get reactivatedSuccess => _value('reactivatedSuccess');
  String get confirmDeactivateTitle => _value('confirmDeactivateTitle');
  String get confirmDeactivateBody => _value('confirmDeactivateBody');
  String get confirmReactivateTitle => _value('confirmReactivateTitle');
  String get confirmReactivateBody => _value('confirmReactivateBody');

  static const Map<String, String> _en = {
    'title': 'Expense types',
    'description':
        'Manage the expense types available for trip expenses without deleting historical records.',
    'addType': 'Add expense type',
    'editType': 'Edit expense type',
    'nameLabel': 'Name',
    'nameHint': 'e.g. Fuel, road fees, loading',
    'nameRequired': 'Expense type name is required.',
    'save': 'Save',
    'cancel': 'Cancel',
    'saving': 'Saving...',
    'status': 'Status',
    'active': 'Active',
    'inactive': 'Inactive',
    'all': 'All',
    'actions': 'Actions',
    'edit': 'Edit',
    'deactivate': 'Deactivate',
    'reactivate': 'Reactivate',
    'retry': 'Retry',
    'loading': 'Loading expense types...',
    'noTypes': 'No expense types have been added yet.',
    'noFilteredTypes': 'No expense types match this status filter.',
    'permissionViewFailure': 'This role cannot view expense types.',
    'permissionManageFailure': 'This role cannot manage expense types.',
    'duplicateNameFailure': 'An expense type with this name already exists.',
    'notFoundFailure': 'The expense type was not found in this company.',
    'genericFailure': 'The expense type action could not be completed.',
    'createdSuccess': 'Expense type created.',
    'updatedSuccess': 'Expense type updated.',
    'deactivatedSuccess': 'Expense type deactivated.',
    'reactivatedSuccess': 'Expense type reactivated.',
    'confirmDeactivateTitle': 'Deactivate expense type?',
    'confirmDeactivateBody':
        'The type will stop appearing when adding trip expenses, but existing trip expense history will remain unchanged.',
    'confirmReactivateTitle': 'Reactivate expense type?',
    'confirmReactivateBody':
        'The type will become available again when adding trip expenses.',
  };

  static const Map<String, String> _ar = {
    'title': 'أنواع المصروفات',
    'description':
        'إدارة أنواع مصروفات الرحلات المتاحة مع الحفاظ على السجلات التاريخية دون حذف.',
    'addType': 'إضافة نوع مصروف',
    'editType': 'تعديل نوع المصروف',
    'nameLabel': 'الاسم',
    'nameHint': 'مثال: وقود، رسوم طريق، تحميل',
    'nameRequired': 'اسم نوع المصروف مطلوب.',
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'saving': 'جاري الحفظ...',
    'status': 'الحالة',
    'active': 'نشط',
    'inactive': 'غير نشط',
    'all': 'الكل',
    'actions': 'الإجراءات',
    'edit': 'تعديل',
    'deactivate': 'تعطيل',
    'reactivate': 'إعادة تفعيل',
    'retry': 'إعادة المحاولة',
    'loading': 'جاري تحميل أنواع المصروفات...',
    'noTypes': 'لم تتم إضافة أي أنواع مصروفات بعد.',
    'noFilteredTypes': 'لا توجد أنواع مصروفات مطابقة لفلتر الحالة الحالي.',
    'permissionViewFailure': 'هذا الدور غير مسموح له بعرض أنواع المصروفات.',
    'permissionManageFailure': 'هذا الدور غير مسموح له بإدارة أنواع المصروفات.',
    'duplicateNameFailure': 'يوجد نوع مصروف بهذا الاسم بالفعل.',
    'notFoundFailure': 'تعذر العثور على نوع المصروف داخل هذه الشركة.',
    'genericFailure': 'تعذر إكمال إجراء نوع المصروف.',
    'createdSuccess': 'تم إنشاء نوع المصروف.',
    'updatedSuccess': 'تم تحديث نوع المصروف.',
    'deactivatedSuccess': 'تم تعطيل نوع المصروف.',
    'reactivatedSuccess': 'تمت إعادة تفعيل نوع المصروف.',
    'confirmDeactivateTitle': 'تعطيل نوع المصروف؟',
    'confirmDeactivateBody':
        'لن يظهر النوع عند إضافة مصروفات جديدة للرحلات، مع بقاء سجل المصروفات الحالي دون تغيير.',
    'confirmReactivateTitle': 'إعادة تفعيل نوع المصروف؟',
    'confirmReactivateBody':
        'سيصبح نوع المصروف متاحًا مرة أخرى عند إضافة مصروفات الرحلات.',
  };
}

extension ExpenseTypesLocalizationsContextX on BuildContext {
  ExpenseTypesLocalizations get expenseTypesL10n =>
      ExpenseTypesLocalizations.forLocale(Localizations.localeOf(this));
}
