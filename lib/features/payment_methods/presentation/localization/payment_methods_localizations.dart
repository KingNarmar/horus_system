import 'package:flutter/widgets.dart';

final class PaymentMethodsLocalizations {
  final Map<String, String> _values;

  const PaymentMethodsLocalizations._(this._values);

  factory PaymentMethodsLocalizations.forLocale(Locale locale) {
    return locale.languageCode == 'ar'
        ? const PaymentMethodsLocalizations._(_ar)
        : const PaymentMethodsLocalizations._(_en);
  }

  String _value(String key) => _values[key]!;

  String get title => _value('title');
  String get description => _value('description');
  String get addMethod => _value('addMethod');
  String get editMethod => _value('editMethod');
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
  String get noMethods => _value('noMethods');
  String get noFilteredMethods => _value('noFilteredMethods');
  String get loadFailed => _value('loadFailed');
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
    'title': 'Payment methods',
    'description':
        'Manage the payment methods available to this company without deleting financial history.',
    'addMethod': 'Add payment method',
    'editMethod': 'Edit payment method',
    'nameLabel': 'Name',
    'nameHint': 'e.g. Cash, bank transfer, cheque',
    'nameRequired': 'Payment method name is required.',
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
    'loading': 'Loading payment methods...',
    'noMethods': 'No payment methods have been added yet.',
    'noFilteredMethods': 'No payment methods match this status filter.',
    'loadFailed': 'Payment methods could not be loaded.',
    'permissionViewFailure': 'This role cannot view payment methods.',
    'permissionManageFailure': 'This role cannot manage payment methods.',
    'duplicateNameFailure': 'A payment method with this name already exists.',
    'notFoundFailure': 'The payment method was not found in this company.',
    'genericFailure': 'The payment method action could not be completed.',
    'createdSuccess': 'Payment method created.',
    'updatedSuccess': 'Payment method updated.',
    'deactivatedSuccess': 'Payment method deactivated.',
    'reactivatedSuccess': 'Payment method reactivated.',
    'confirmDeactivateTitle': 'Deactivate payment method?',
    'confirmDeactivateBody':
        'The method will stop appearing in payment selection lists, but existing financial history will remain unchanged.',
    'confirmReactivateTitle': 'Reactivate payment method?',
    'confirmReactivateBody':
        'The method will become available again in payment selection lists.',
  };

  static const Map<String, String> _ar = {
    'title': 'طرق الدفع',
    'description':
        'إدارة طرق الدفع المتاحة لهذه الشركة مع الحفاظ على السجل المالي دون حذف.',
    'addMethod': 'إضافة طريقة دفع',
    'editMethod': 'تعديل طريقة الدفع',
    'nameLabel': 'الاسم',
    'nameHint': 'مثال: نقدي، تحويل بنكي، شيك',
    'nameRequired': 'اسم طريقة الدفع مطلوب.',
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'saving': 'جاري الحفظ...',
    'status': 'الحالة',
    'active': 'نشطة',
    'inactive': 'غير نشطة',
    'all': 'الكل',
    'actions': 'الإجراءات',
    'edit': 'تعديل',
    'deactivate': 'تعطيل',
    'reactivate': 'إعادة تفعيل',
    'retry': 'إعادة المحاولة',
    'loading': 'جاري تحميل طرق الدفع...',
    'noMethods': 'لم تتم إضافة أي طرق دفع بعد.',
    'noFilteredMethods': 'لا توجد طرق دفع مطابقة لفلتر الحالة الحالي.',
    'loadFailed': 'تعذر تحميل طرق الدفع.',
    'permissionViewFailure': 'هذا الدور غير مسموح له بعرض طرق الدفع.',
    'permissionManageFailure': 'هذا الدور غير مسموح له بإدارة طرق الدفع.',
    'duplicateNameFailure': 'توجد طريقة دفع بهذا الاسم بالفعل.',
    'notFoundFailure': 'تعذر العثور على طريقة الدفع داخل هذه الشركة.',
    'genericFailure': 'تعذر إكمال إجراء طريقة الدفع.',
    'createdSuccess': 'تم إنشاء طريقة الدفع.',
    'updatedSuccess': 'تم تحديث طريقة الدفع.',
    'deactivatedSuccess': 'تم تعطيل طريقة الدفع.',
    'reactivatedSuccess': 'تمت إعادة تفعيل طريقة الدفع.',
    'confirmDeactivateTitle': 'تعطيل طريقة الدفع؟',
    'confirmDeactivateBody':
        'لن تظهر الطريقة بعد ذلك في قوائم اختيار الدفع، مع بقاء السجل المالي الحالي دون تغيير.',
    'confirmReactivateTitle': 'إعادة تفعيل طريقة الدفع؟',
    'confirmReactivateBody':
        'ستصبح طريقة الدفع متاحة مرة أخرى في قوائم اختيار الدفع.',
  };
}

extension PaymentMethodsLocalizationsContextX on BuildContext {
  PaymentMethodsLocalizations get paymentMethodsL10n =>
      PaymentMethodsLocalizations.forLocale(Localizations.localeOf(this));
}
