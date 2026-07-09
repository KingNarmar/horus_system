import '../../../../l10n/app_localizations.dart';

extension CustomersLocalizationsX on AppLocalizations {
  String customerDetailsTitle(String name) => customerDetailsTitle(name);

  String customerAuditActionLabel(String action) {
    return switch (action) {
      'created' => customerAuditActionCreated,
      'updated' => customerAuditActionUpdated,
      'deactivated' => customerAuditActionDeactivated,
      'reactivated' => customerAuditActionReactivated,
      'status_changed' => customerAuditActionStatusChanged,
      _ => action,
    };
  }

  String customerAuditRoleLabel(String? role) {
    if (role == null || role.trim().isEmpty) return customerNotAvailable;

    return switch (role) {
      'owner' => roleOwner,
      'admin' => roleAdmin,
      'operations' => roleOperations,
      'accountant' => roleAccountant,
      'viewer' => roleViewer,
      'driver' => roleDriver,
      _ => role,
    };
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
    if (value == null) return customerEmptyValue;

    final stringValue = value.toString().trim();
    if (stringValue.isEmpty) return customerEmptyValue;

    if (key == 'is_active') {
      if (value == true || stringValue == 'true') return activeStatus;
      if (value == false || stringValue == 'false') return inactiveStatus;
    }

    return stringValue;
  }
}
