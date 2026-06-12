import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension CommonErrorLocalizationsX on AppLocalizations {
  bool get _isArabicError => localeName.startsWith('ar');

  String localizedErrorMessage(String message) {
    return switch (message) {
      'Unexpected error occurred.' => _isArabicError ? 'حدث خطأ غير متوقع.' : message,
      'Company id is required.' => _isArabicError ? 'معرّف الشركة مطلوب.' : message,
      'Company context is required.' => _isArabicError ? 'سياق الشركة مطلوب.' : message,
      'Selected company is not available for the current user.' => _isArabicError ? 'الشركة المحددة غير متاحة للمستخدم الحالي.' : message,
      'This role cannot view company users.' => _isArabicError ? 'هذا الدور لا يمكنه عرض مستخدمي الشركة.' : message,
      'Customers access is not allowed.' => _isArabicError ? 'لا يوجد صلاحية للوصول إلى العملاء.' : message,
      'Customers management is not allowed.' => _isArabicError ? 'لا يوجد صلاحية لإدارة العملاء.' : message,
      'Customer id is required.' => _isArabicError ? 'معرّف العميل مطلوب.' : message,
      'Customer name is required.' => _isArabicError ? 'اسم العميل مطلوب.' : message,
      'Credit limit cannot be negative.' => _isArabicError ? 'حد الائتمان لا يمكن أن يكون رقمًا سالبًا.' : message,
      'Audit entity id is required.' => _isArabicError ? 'معرّف سجل المراجعة مطلوب.' : message,
      'Audit description is required.' => _isArabicError ? 'وصف سجل المراجعة مطلوب.' : message,
      'Password is required.' => _isArabicError ? 'كلمة المرور مطلوبة.' : message,
      'Password must be at least 6 characters.' => _isArabicError ? 'كلمة المرور يجب ألا تقل عن 6 أحرف.' : message,
      _ => message,
    };
  }
}

extension CustomerFilterLocalizationsX on AppLocalizations {
  bool get _isArabic => localeName.startsWith('ar');

  String get reactivateCustomerButton => _isArabic ? 'إعادة تفعيل' : 'Reactivate';

  String get searchCustomersHint => _isArabic
      ? 'ابحث في العملاء بالاسم أو المسؤول أو الهاتف أو البريد أو المدينة أو الدولة أو الرقم الضريبي'
      : 'Search customers by name, contact, phone, email, city, country, or TRN';

  String get customersStatusAllFilter => _isArabic ? 'الكل' : 'All';

  String get customersStatusActiveFilter => _isArabic ? 'النشط' : 'Active';

  String get customersStatusInactiveFilter =>
      _isArabic ? 'غير النشط' : 'Inactive';

  String get noCustomersMatchFilters => _isArabic
      ? 'لا يوجد عملاء مطابقون للبحث أو فلتر الحالة الحالي.'
      : 'No customers match the current search or status filter.';
}
