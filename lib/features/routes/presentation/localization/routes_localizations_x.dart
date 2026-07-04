import '../../../../l10n/app_localizations.dart';

extension RoutesLocalizationsX on AppLocalizations {
  String get activeStatusLabel => routeActiveStatusLabel;

  String get inactiveStatusLabel => routeInactiveStatusLabel;

  String get editButton => routeEditButton;

  String get routeEmptyValue => '-';

  String get emptyValue => '-';

  String routeAuditActionLabel(String action) {
    return switch (action) {
      'created' => routeAuditActionCreated,
      'updated' => routeAuditActionUpdated,
      'deactivated' => routeAuditActionDeactivated,
      'reactivated' => routeAuditActionReactivated,
      'status_changed' => routeAuditActionStatusChanged,
      _ => action,
    };
  }

  String routeAuditRoleLabel(String? role) {
    return switch (role) {
      'owner' => roleOwner,
      'admin' => roleAdmin,
      'operations' => roleOperations,
      'accountant' => roleAccountant,
      'viewer' => roleViewer,
      'driver' => roleDriver,
      null || '' => routeNotAvailable,
      _ => role,
    };
  }

  String routeAuditFieldLabel(String key) {
    return switch (key) {
      'loading_location' => loadingLocationLabel,
      'unloading_location' => unloadingLocationLabel,
      'governorate_from' => governorateFromLabel,
      'governorate_to' => governorateToLabel,
      'default_freight_price' => defaultFreightPriceLabel,
      'notes' => routeNotesLabel,
      'is_active' => routeStatusHeader,
      _ => key,
    };
  }

  String routeAuditValueLabel(String key, Object? value) {
    if (value == null) return routeEmptyValue;

    if (key == 'is_active') {
      return value == true ? activeStatusLabel : inactiveStatusLabel;
    }

    return value.toString();
  }
}
