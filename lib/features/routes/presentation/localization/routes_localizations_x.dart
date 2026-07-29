import '../../../../l10n/app_localizations.dart';
import '../../../audit/presentation/localization/audit_display_localizations_x.dart';

extension RoutesLocalizationsX on AppLocalizations {
  String get activeStatusLabel => routeActiveStatusLabel;

  String get inactiveStatusLabel => routeInactiveStatusLabel;

  String get editButton => routeEditButton;

  String get routeEmptyValue => '-';

  String get emptyValue => '-';

  String routeAuditActionLabel(String action) {
    return auditActionValueDisplayLabel(action);
  }

  String routeAuditRoleLabel(String? role) {
    return auditRoleDisplayLabel(role);
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
