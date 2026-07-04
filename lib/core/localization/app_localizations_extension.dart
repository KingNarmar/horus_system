import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../errors/common_failures.dart';
import '../errors/failure.dart';
import '../errors/failure_codes.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension CommonErrorLocalizationsX on AppLocalizations {
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
        failurePermissionDriverFinanceView,
      FailureCodes.permissionDriverFinanceManagement =>
        failurePermissionDriverFinanceManagement,
      FailureCodes.permissionCompanyExpensesView =>
        failurePermissionCompanyExpensesView,
      FailureCodes.permissionCompanyExpensesManagement =>
        failurePermissionCompanyExpensesManagement,
      FailureCodes.validationTripIdRequired => failureValidationTripIdRequired,
      FailureCodes.validationTripExpenseIdRequired =>
        failureValidationTripExpenseIdRequired,
      FailureCodes.validationTripExpenseTypeRequired =>
        failureValidationTripExpenseTypeRequired,
      FailureCodes.validationTripExpenseNameRequired =>
        failureValidationTripExpenseNameRequired,
      FailureCodes.validationTripExpenseAmountPositive =>
        failureValidationTripExpenseAmountPositive,
      FailureCodes.validationDriverFinanceAmountPositive =>
        failureValidationDriverFinanceAmountPositive,
      FailureCodes.validationCompanyExpenseIdRequired =>
        failureValidationCompanyExpenseIdRequired,
      FailureCodes.validationCompanyExpenseCategoryRequired =>
        failureValidationCompanyExpenseCategoryRequired,
      FailureCodes.validationCompanyExpenseAmountPositive =>
        failureValidationCompanyExpenseAmountPositive,
      FailureCodes.validationCompanyNameRequired => companyNameRequired,
      FailureCodes.serverError => _genericServerErrorMessage,
      _ => _safeFallbackErrorMessage(failure),
    };
  }
}
