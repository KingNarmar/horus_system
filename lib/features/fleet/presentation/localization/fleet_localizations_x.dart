import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_status.dart';

extension FleetLocalizationsX on AppLocalizations {
  bool get _isArabic => localeName.startsWith('ar');

  String get editButton => fleetEditButton;

  String get fleetBasicInfo =>
      _isArabic ? 'البيانات الأساسية' : 'Basic information';

  String get fleetAccountability =>
      _isArabic ? 'المسؤولية والمتابعة' : 'Accountability';

  String get fleetActivityTimeline =>
      _isArabic ? 'سجل النشاط' : 'Activity timeline';

  String get fleetCreatedBy => _isArabic ? 'أنشأه' : 'Created by';

  String get fleetCreatedRole => _isArabic ? 'دور المنشئ' : 'Created role';

  String get fleetCreatedAt => _isArabic ? 'تاريخ الإنشاء' : 'Created at';

  String get fleetLastActivityBy =>
      _isArabic ? 'آخر إجراء بواسطة' : 'Last activity by';

  String get fleetLastActivityRole =>
      _isArabic ? 'دور آخر مستخدم' : 'Last activity role';

  String get fleetLastActivityAt =>
      _isArabic ? 'وقت آخر إجراء' : 'Last activity at';

  String get fleetLoadingActivity =>
      _isArabic ? 'جاري تحميل سجل النشاط...' : 'Loading activity...';

  String get fleetNoActivityFound => _isArabic
      ? 'لا يوجد نشاط مسجل لهذا الأصل.'
      : 'No activity found for this asset.';

  String get fleetUnknownUser =>
      _isArabic ? 'مستخدم غير معروف' : 'Unknown user';

  String get fleetNotAvailable => _isArabic ? 'غير متاح' : 'Not available';

  String get fleetChanges => _isArabic ? 'التغييرات' : 'Changes';

  String get emptyValue => '-';

  String fleetDetailsTitle(String plateNumber) {
    return _isArabic
        ? 'تفاصيل الأصل: $plateNumber'
        : 'Fleet asset details: $plateNumber';
  }

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
      'created' => _isArabic ? 'تم الإنشاء' : 'Created',
      'updated' => _isArabic ? 'تم التعديل' : 'Updated',
      'deactivated' => _isArabic ? 'تم التعطيل' : 'Deactivated',
      'reactivated' => _isArabic ? 'تم التفعيل' : 'Reactivated',
      'status_changed' => _isArabic ? 'تم تغيير الحالة' : 'Status changed',
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
