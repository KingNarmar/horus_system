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
      FailureCodes.permissionCustomersView => failurePermissionCustomersView,
      FailureCodes.permissionCustomersManagement =>
        failurePermissionCustomersManagement,
      FailureCodes.validationCustomerIdRequired =>
        failureValidationCustomerIdRequired,
      FailureCodes.validationCustomerNameRequired =>
        failureValidationCustomerNameRequired,
      FailureCodes.validationCreditLimitNegative =>
        failureValidationCreditLimitNegative,
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
        failureValidationDriverIdRequired,
      FailureCodes.validationDriverNameRequired =>
        failureValidationDriverNameRequired,
      FailureCodes.permissionDriversManagement =>
        failurePermissionDriversManagement,
      FailureCodes.permissionDriversView => failurePermissionDriversView,
      FailureCodes.permissionFleetManagement =>
        failurePermissionFleetManagement,
      FailureCodes.permissionFleetView => failurePermissionFleetView,
      FailureCodes.validationFleetPlateRequired =>
        failureValidationFleetPlateRequired,
      FailureCodes.validationFleetFuelConsumptionNegative =>
        failureValidationFleetFuelConsumptionNegative,
      FailureCodes.permissionRoutesManagement =>
        failurePermissionRoutesManagement,
      FailureCodes.permissionRoutesView => failurePermissionRoutesView,
      FailureCodes.validationRouteLoadingLocationRequired =>
        failureValidationRouteLoadingLocationRequired,
      FailureCodes.validationRouteUnloadingLocationRequired =>
        failureValidationRouteUnloadingLocationRequired,
      FailureCodes.validationRouteFreightPriceNegative =>
        failureValidationRouteFreightPriceNegative,
      FailureCodes.permissionTripExpensesView =>
        failurePermissionTripExpensesView,
      FailureCodes.permissionTripExpensesManagement =>
        failurePermissionTripExpensesManagement,
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
        failureValidationTripExpenseIdRequired,
      FailureCodes.validationTripExpenseTypeRequired =>
        failureValidationTripExpenseTypeRequired,
      FailureCodes.validationTripExpenseNameRequired =>
        failureValidationTripExpenseNameRequired,
      FailureCodes.validationTripExpenseAmountPositive =>
        failureValidationTripExpenseAmountPositive,
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
      FailureCodes.validationCompanyNameRequired => companyNameRequired,
      FailureCodes.serverError => _genericServerErrorMessage,
      _ => _safeFallbackErrorMessage(failure),
    };
  }
}
