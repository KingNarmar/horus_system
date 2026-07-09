import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_status.dart';

extension FleetLocalizationsX on AppLocalizations {
  String get editButton => fleetEditButton;

  String get emptyValue => '-';

  String vehicleStatusText(VehicleStatus status) {
    return switch (status) {
      VehicleStatus.available => vehicleStatusAvailable,
      VehicleStatus.onTrip => vehicleStatusOnTrip,
      VehicleStatus.loading => vehicleStatusLoading,
      VehicleStatus.unloading => vehicleStatusUnloading,
      VehicleStatus.maintenance => vehicleStatusMaintenance,
      VehicleStatus.stopped => vehicleStatusStopped,
      VehicleStatus.inactive => vehicleStatusInactive,
    };
  }

  String fleetAuditActionLabel(String action) {
    return switch (action) {
      'created' => fleetAuditActionCreated,
      'updated' => fleetAuditActionUpdated,
      'deactivated' => fleetAuditActionDeactivated,
      'reactivated' => fleetAuditActionReactivated,
      'status_changed' => fleetAuditActionStatusChanged,
      _ => action,
    };
  }

  String fleetAuditRoleLabel(String? role) {
    if (role == null || role.trim().isEmpty) return fleetNotAvailable;

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

  String fleetAuditFieldLabel(String key) {
    return switch (key) {
      'plate_number' => plateNumberLabel,
      'license_expiry_date' => vehicleLicenseExpiryDateLabel,
      'expected_fuel_consumption' => expectedFuelConsumptionLabel,
      'status' => vehicleStatusLabel,
      'notes' => vehicleNotesLabel,
      'technical_notes' => technicalNotesLabel,
      'is_active' => fleetStatusActiveFilter,
      _ => key,
    };
  }

  String fleetAuditValueLabel(String key, Object? value) {
    if (value == null) return emptyValue;

    final text = value.toString().trim();
    if (text.isEmpty) return emptyValue;

    if (key == 'is_active') {
      if (value == true || text == 'true') return activeStatus;
      if (value == false || text == 'false') return inactiveStatus;
    }

    if (key == 'status') {
      return vehicleStatusText(VehicleStatusX.fromValue(text));
    }

    return text;
  }
}
