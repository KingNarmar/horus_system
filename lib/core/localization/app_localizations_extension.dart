import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../errors/common_failures.dart';
import '../errors/failure.dart';
import '../errors/failure_codes.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension CommonErrorLocalizationsX on AppLocalizations {
  bool get _isArabicError => localeName.startsWith('ar');

  String get _genericUnexpectedErrorMessage => failureUnexpectedError;

  String get _genericServerErrorMessage => failureServerError;

  String _safeFallbackErrorMessage(Failure failure) {
    if (failure is ServerFailure) return _genericServerErrorMessage;
    if (failure is UnexpectedFailure) return _genericUnexpectedErrorMessage;

    return failure.message ?? failure.code;
  }

  String localizedErrorMessage(Failure failure) {
    return switch (failure.code) {
      FailureCodes.unexpectedError => _genericUnexpectedErrorMessage,
      FailureCodes.validationCompanyIdRequired =>
        failureValidationCompanyIdRequired,
      FailureCodes.validationCompanyContextRequired =>
        failureValidationCompanyContextRequired,
      'company_not_available' => failureCompanyNotAvailable,
      FailureCodes.permissionCompanyUsersView =>
        failurePermissionCompanyUsersView,
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
        failureValidationAuditEntityIdRequired,
      FailureCodes.validationAuditDescriptionRequired =>
        failureValidationAuditDescriptionRequired,
      FailureCodes.authPasswordRequired => passwordRequired,
      FailureCodes.authPasswordTooShort => passwordMinLength,
      FailureCodes.authEmailRequired => emailRequired,
      FailureCodes.authFullNameRequired => fullNameRequired,
      FailureCodes.authPhoneRequired => phoneNumberRequired,
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
      FailureCodes.permissionCompanyExpensesView =>
        _isArabicError
            ? 'لا يوجد صلاحية لعرض مصروفات الشركة.'
            : 'Company expenses access is not allowed.',
      FailureCodes.permissionCompanyExpensesManagement =>
        _isArabicError
            ? 'لا يوجد صلاحية لإدارة مصروفات الشركة.'
            : 'Company expenses management is not allowed.',
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
      FailureCodes.validationCompanyExpenseIdRequired =>
        _isArabicError
            ? 'معرّف مصروف الشركة مطلوب.'
            : 'Company expense id is required.',
      FailureCodes.validationCompanyExpenseCategoryRequired =>
        _isArabicError
            ? 'تصنيف مصروف الشركة مطلوب.'
            : 'Company expense category is required.',
      FailureCodes.validationCompanyExpenseAmountPositive =>
        _isArabicError
            ? 'مبلغ مصروف الشركة لازم يكون أكبر من صفر.'
            : 'Company expense amount must be greater than zero.',
      FailureCodes.validationCompanyNameRequired =>
        _isArabicError ? 'اسم الشركة مطلوب.' : 'Company name is required.',
      FailureCodes.serverError => _genericServerErrorMessage,
      _ => _safeFallbackErrorMessage(failure),
    };
  }
}
