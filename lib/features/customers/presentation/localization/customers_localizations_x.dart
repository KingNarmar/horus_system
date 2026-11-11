import '../../../../l10n/app_localizations.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../subscriptions/domain/failures/quota_failure_codes.dart';
import '../../../audit/presentation/localization/audit_display_localizations_x.dart';

extension CustomersLocalizationsX on AppLocalizations {
  String localizedCustomerFailureMessage(Failure failure) {
    return switch (failure.code) {
      QuotaFailureCodes.customersReached => failureQuotaCustomersReached,
      QuotaFailureCodes.unavailable => failureQuotaUnavailable,
      _ => localizedErrorMessage(failure),
    };
  }

  String customerAuditActionLabel(String action) {
    return auditActionValueDisplayLabel(action);
  }

  String customerAuditRoleLabel(String? role) {
    return auditRoleDisplayLabel(role);
  }

  String customerAuditFieldLabel(String key) {
    return switch (key) {
      'name' => customerNameLabel,
      'contact_person' => contactPersonLabel,
      'phone' => phoneLabel,
      'email' => emailLabel,
      'tax_registration_number' => taxRegistrationNumberLabel,
      'address' => addressLabel,
      'city' => cityLabel,
      'country' => countryLabel,
      'credit_limit' => creditLimitLabel,
      'is_active' => statusHeader,
      _ => key,
    };
  }

  String customerAuditValueLabel(String key, Object? value) {
    if (value == null) return customerNotAvailable;

    final stringValue = value.toString().trim();
    if (stringValue.isEmpty) return customerNotAvailable;

    if (key == 'is_active') {
      if (value == true || stringValue == 'true') return activeStatus;
      if (value == false || stringValue == 'false') return inactiveStatus;
    }

    return stringValue;
  }
}
