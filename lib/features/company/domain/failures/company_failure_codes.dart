abstract final class CompanyFailureCodes {
  static const authRequired = 'company_auth_required';
  static const permissionSettingsManagement =
      'permission_company_settings_management';
  static const validationBaseCurrencyInvalid =
      'validation_company_base_currency_invalid';
  static const validationBaseCurrencyFractionDigitsInvalid =
      'validation_company_base_currency_fraction_digits_invalid';
  static const validationBusinessTimezoneRequired =
      'validation_company_business_timezone_required';
  static const validationBusinessTimezoneInvalid =
      'validation_company_business_timezone_invalid';
  static const conflictBaseCurrencyLocked =
      'conflict_company_base_currency_locked';
  static const conflictRegionalSettingsNotConfigured =
      'conflict_company_regional_settings_not_configured';
  static const companyNotAvailable = 'company_not_available';
  static const notFound = 'company_not_found';
}
