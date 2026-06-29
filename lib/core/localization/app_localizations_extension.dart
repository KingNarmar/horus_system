import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../errors/failure.dart';
import '../errors/failure_codes.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension CommonErrorLocalizationsX on AppLocalizations {
  bool get _isArabicError => localeName.startsWith('ar');

  String localizedErrorMessage(Failure failure) {
    return switch (failure.code) {
      FailureCodes.unexpectedError =>
        _isArabicError ? 'حدث خطأ غير متوقع.' : 'Unexpected error occurred.',
      FailureCodes.validationCompanyIdRequired =>
        _isArabicError ? 'معرّف الشركة مطلوب.' : 'Company id is required.',
      FailureCodes.validationCompanyContextRequired =>
        _isArabicError ? 'سياق الشركة مطلوب.' : 'Company context is required.',
      'company_not_available' =>
        _isArabicError
            ? 'الشركة المحددة غير متاحة للمستخدم الحالي.'
            : 'Selected company is not available for the current user.',
      FailureCodes.permissionCompanyUsersView =>
        _isArabicError
            ? 'هذا الدور لا يمكنه عرض مستخدمي الشركة.'
            : 'This role cannot view company users.',
      FailureCodes.permissionCustomersView =>
        _isArabicError
            ? 'لا يوجد صلاحية للوصول إلى العملاء.'
            : 'Customers access is not allowed.',
      FailureCodes.permissionCustomersManagement =>
        _isArabicError
            ? 'لا يوجد صلاحية لإدارة العملاء.'
            : 'Customers management is not allowed.',
      FailureCodes.validationCustomerIdRequired =>
        _isArabicError ? 'معرّف العميل مطلوب.' : 'Customer id is required.',
      FailureCodes.validationCustomerNameRequired =>
        _isArabicError ? 'اسم العميل مطلوب.' : 'Customer name is required.',
      FailureCodes.validationCreditLimitNegative =>
        _isArabicError
            ? 'حد الائتمان لا يمكن أن يكون رقمًا سالبًا.'
            : 'Credit limit cannot be negative.',
      FailureCodes.validationAuditEntityIdRequired =>
        _isArabicError
            ? 'معرّف سجل المراجعة مطلوب.'
            : 'Audit entity id is required.',
      FailureCodes.validationAuditDescriptionRequired =>
        _isArabicError
            ? 'وصف سجل المراجعة مطلوب.'
            : 'Audit description is required.',
      FailureCodes.authPasswordRequired =>
        _isArabicError ? 'كلمة المرور مطلوبة.' : 'Password is required.',
      FailureCodes.authPasswordTooShort =>
        _isArabicError
            ? 'كلمة المرور يجب ألا تقل عن 6 أحرف.'
            : 'Password must be at least 6 characters.',
      FailureCodes.authEmailRequired =>
        _isArabicError ? 'البريد الإلكتروني مطلوب.' : 'Email is required.',
      FailureCodes.authFullNameRequired =>
        _isArabicError ? 'الاسم بالكامل مطلوب.' : 'Full name is required.',
      FailureCodes.authPhoneRequired =>
        _isArabicError ? 'رقم الهاتف مطلوب.' : 'Phone number is required.',
      FailureCodes.validationDriverIdRequired =>
        _isArabicError ? 'معرّف السائق مطلوب.' : 'Driver id is required.',
      FailureCodes.validationDriverNameRequired =>
        _isArabicError ? 'اسم السائق مطلوب.' : 'Driver name is required.',
      FailureCodes.permissionDriversManagement =>
        _isArabicError
            ? 'لا يوجد صلاحية لإدارة السائقين.'
            : 'Drivers management is not allowed.',
      FailureCodes.permissionDriversView =>
        _isArabicError
            ? 'لا يوجد صلاحية للوصول إلى السائقين.'
            : 'You are not allowed to view drivers.',
      FailureCodes.permissionFleetManagement =>
        _isArabicError
            ? 'لا يوجد صلاحية لإدارة الأسطول.'
            : 'Fleet management is not allowed.',
      FailureCodes.permissionFleetView =>
        _isArabicError
            ? 'لا يوجد صلاحية للوصول إلى الأسطول.'
            : 'You are not allowed to view fleet.',
      FailureCodes.validationFleetPlateRequired =>
        _isArabicError ? 'رقم اللوحة مطلوب.' : 'Plate number is required.',
      FailureCodes.validationFleetFuelConsumptionNegative =>
        _isArabicError
            ? 'استهلاك الوقود المتوقع لا يمكن أن يكون رقمًا سالبًا.'
            : 'Expected fuel consumption cannot be negative.',
      FailureCodes.permissionRoutesManagement =>
        _isArabicError
            ? 'لا يوجد صلاحية لإدارة المسارات.'
            : 'Routes management is not allowed.',
      FailureCodes.permissionRoutesView =>
        _isArabicError
            ? 'لا يوجد صلاحية للوصول إلى المسارات.'
            : 'You are not allowed to view routes.',
      FailureCodes.validationRouteLoadingLocationRequired =>
        _isArabicError
            ? 'مكان التحميل مطلوب.'
            : 'Loading location is required.',
      FailureCodes.validationRouteUnloadingLocationRequired =>
        _isArabicError
            ? 'مكان التفريغ مطلوب.'
            : 'Unloading location is required.',
      FailureCodes.validationRouteFreightPriceNegative =>
        _isArabicError
            ? 'سعر النقل الافتراضي لا يمكن أن يكون رقمًا سالبًا.'
            : 'Default freight price cannot be negative.',
      FailureCodes.permissionTripExpensesView =>
        _isArabicError
            ? 'لا يوجد صلاحية لعرض مصروفات الرحلة.'
            : 'Trip expenses access is not allowed.',
      FailureCodes.permissionTripExpensesManagement =>
        _isArabicError
            ? 'لا يوجد صلاحية لإدارة مصروفات الرحلة.'
            : 'Trip expenses management is not allowed.',
      FailureCodes.permissionDriverFinanceView =>
        _isArabicError
            ? 'لا يوجد صلاحية لعرض الحركات المالية للسائق.'
            : 'Driver finance access is not allowed.',
      FailureCodes.permissionDriverFinanceManagement =>
        _isArabicError
            ? 'لا يوجد صلاحية لإدارة الحركات المالية للسائق.'
            : 'Driver finance management is not allowed.',
      FailureCodes.validationTripIdRequired =>
        _isArabicError ? 'معرّف الرحلة مطلوب.' : 'Trip id is required.',
      FailureCodes.validationTripExpenseIdRequired =>
        _isArabicError
            ? 'معرّف مصروف الرحلة مطلوب.'
            : 'Trip expense id is required.',
      FailureCodes.validationTripExpenseTypeRequired =>
        _isArabicError ? 'نوع المصروف مطلوب.' : 'Expense type is required.',
      FailureCodes.validationTripExpenseNameRequired =>
        _isArabicError ? 'اسم المصروف مطلوب.' : 'Expense name is required.',
      FailureCodes.validationTripExpenseAmountPositive =>
        _isArabicError
            ? 'مبلغ المصروف لازم يكون أكبر من صفر.'
            : 'Expense amount must be greater than zero.',
      FailureCodes.validationDriverFinanceAmountPositive =>
        _isArabicError
            ? 'مبلغ حركة السائق لازم يكون أكبر من صفر.'
            : 'Driver financial movement amount must be greater than zero.',
      FailureCodes.validationCompanyNameRequired =>
        _isArabicError ? 'اسم الشركة مطلوب.' : 'Company name is required.',
      FailureCodes.serverError =>
        failure.message ??
            (_isArabicError ? 'حدث خطأ في الخادم.' : 'Server error occurred.'),
      _ => failure.message ?? failure.code,
    };
  }
}

extension CustomerFilterLocalizationsX on AppLocalizations {
  bool get _isArabic => localeName.startsWith('ar');

  String get reactivateCustomerButton =>
      _isArabic ? 'إعادة تفعيل' : 'Reactivate';

  String get searchCustomersHint =>
      _isArabic ? 'ابحث في العملاء' : 'Search customers';

  String get customersStatusAllFilter => _isArabic ? 'الكل' : 'All';

  String get customersStatusActiveFilter => _isArabic ? 'النشط' : 'Active';

  String get customersStatusInactiveFilter =>
      _isArabic ? 'غير النشط' : 'Inactive';

  String get noCustomersMatchFilters => _isArabic
      ? 'لا يوجد عملاء مطابقون للبحث أو فلتر الحالة الحالي.'
      : 'No customers match the current search or status filter.';
}
