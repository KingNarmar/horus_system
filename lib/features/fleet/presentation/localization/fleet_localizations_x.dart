import '../../../../l10n/app_localizations.dart';
import '../../../audit/presentation/localization/audit_display_localizations_x.dart';
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
    return auditActionValueDisplayLabel(action);
  }

  String fleetAuditEventLabel(String? event, String action) {
    return switch (event) {
      'fleet_license_document_uploaded' => fleetAuditLicenseDocumentUploaded,
      'fleet_license_document_file_added' => fleetAuditLicenseDocumentFileAdded,
      'fleet_license_document_file_replaced' =>
        fleetAuditLicenseDocumentFileReplaced,
      'fleet_license_document_replaced' => fleetAuditLicenseDocumentReplaced,
      'fleet_license_document_removed' => fleetAuditLicenseDocumentRemoved,
      _ => fleetAuditActionLabel(action),
    };
  }

  String fleetAuditRoleLabel(String? role) {
    return auditRoleDisplayLabel(role);
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
      'license_document_file_name' => fleetLicenseDocumentFileNameField,
      'license_document_mime_type' => fleetLicenseDocumentMimeTypeField,
      'license_document_size_bytes' => fleetLicenseDocumentSizeField,
      'license_document_side' => fleetLicenseDocumentSideField,
      'license_document_removed' => fleetLicenseDocumentRemovedField,
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

    if (key == 'license_document_removed' &&
        (value == true || text == 'true')) {
      return fleetLicenseDocumentRemovedValue;
    }

    if (key == 'license_document_side') {
      return switch (text) {
        'front' => fleetLicenseDocumentFrontValue,
        'back' => fleetLicenseDocumentBackValue,
        'combined' => fleetLicenseDocumentCombinedValue,
        _ => text,
      };
    }

    return text;
  }
}
