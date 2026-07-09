import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/driver_status.dart';

extension DriversLocalizationsX on AppLocalizations {
  String get basicInfo => driverBasicInfo;

  String get accountability => driverAccountability;

  String get activityTimeline => driverActivityTimeline;

  String get createdBy => driverCreatedBy;

  String get createdRole => driverCreatedRole;

  String get createdAt => driverCreatedAt;

  String get lastActivityBy => driverLastActivityBy;

  String get lastActivityRole => driverLastActivityRole;

  String get lastActivityAt => driverLastActivityAt;

  String get loadingActivity => driverLoadingActivity;

  String get noActivityFound => driverNoActivityFound;

  String get emptyValue => '-';

  String get unknownUser => driverUnknownUser;

  String get notAvailable => driverNotAvailable;

  String driverStatusLabel(DriverStatus status) {
    return switch (status) {
      DriverStatus.active => driverStatusActiveLabel,
      DriverStatus.inactive => driverStatusInactiveLabel,
    };
  }

  String auditActionLabel(String action) {
    return switch (action) {
      'created' => driverAuditActionCreated,
      'updated' => driverAuditActionUpdated,
      'deactivated' => driverAuditActionDeactivated,
      'reactivated' => driverAuditActionReactivated,
      'driver_finance_added' => driverAuditActionFinanceAdded,
      _ => action,
    };
  }

  String driverFieldLabel(String field) {
    return switch (field) {
      'full_name' => driverNameLabel,
      'phone' => driverPhoneFieldLabel,
      'national_id' => nationalIdLabel,
      'license_number' => licenseNumberLabel,
      'license_expiry_date' => licenseExpiryDateLabel,
      'notes' => notesLabel,
      'is_active' => driverStatusFieldLabel,
      _ => field,
    };
  }

  String driverValueLabel(String field, Object? value) {
    if (field == 'is_active') {
      return driverStatusLabel(
        value == true ? DriverStatus.active : DriverStatus.inactive,
      );
    }

    final text = value?.toString().trim();
    return text == null || text.isEmpty ? emptyValue : text;
  }
}
