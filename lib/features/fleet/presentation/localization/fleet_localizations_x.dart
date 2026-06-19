import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_status.dart';

extension FleetLocalizationsX on AppLocalizations {
  bool get _isArabic => localeName.startsWith('ar');

  String get fleetTitle => _isArabic ? 'الأسطول' : 'Fleet';
  String get tractorHeadsTab => _isArabic ? 'رؤوس الجر' : 'Tractor heads';
  String get trailersTab => _isArabic ? 'المقطورات' : 'Trailers';
  String get addTractorHeadButton => _isArabic ? 'إضافة رأس جر' : 'Add tractor head';
  String get addTrailerButton => _isArabic ? 'إضافة مقطورة' : 'Add trailer';
  String get editTractorHeadTitle => _isArabic ? 'تعديل رأس جر' : 'Edit tractor head';
  String get editTrailerTitle => _isArabic ? 'تعديل مقطورة' : 'Edit trailer';
  String get plateNumberLabel => _isArabic ? 'رقم اللوحة' : 'Plate number';
  String get plateNumberRequired => _isArabic ? 'رقم اللوحة مطلوب.' : 'Plate number is required.';
  String get vehicleStatusLabel => _isArabic ? 'حالة المركبة' : 'Vehicle status';
  String get vehicleLicenseExpiryDateLabel => _isArabic ? 'تاريخ انتهاء الترخيص' : 'License expiry date';
  String get expectedFuelConsumptionLabel => _isArabic ? 'استهلاك الوقود المتوقع' : 'Expected fuel consumption';
  String get expectedFuelConsumptionInvalid => _isArabic ? 'أدخل رقم صحيح غير سالب.' : 'Enter a valid non-negative number.';
  String get vehicleNotesLabel => _isArabic ? 'ملاحظات' : 'Notes';
  String get technicalNotesLabel => _isArabic ? 'ملاحظات فنية' : 'Technical notes';
  String get searchFleetHint => _isArabic ? 'ابحث برقم اللوحة أو الحالة أو الملاحظات' : 'Search by plate, status, or notes';
  String get fleetStatusAllFilter => _isArabic ? 'الكل' : 'All';
  String get fleetStatusActiveFilter => _isArabic ? 'النشط' : 'Active';
  String get fleetStatusInactiveFilter => _isArabic ? 'غير النشط' : 'Inactive';
  String get noTractorHeadsFound => _isArabic ? 'لا توجد رؤوس جر.' : 'No tractor heads found.';
  String get noTrailersFound => _isArabic ? 'لا توجد مقطورات.' : 'No trailers found.';
  String get noFleetMatchFilters => _isArabic ? 'لا توجد أصول مطابقة للبحث أو الفلتر الحالي.' : 'No fleet assets match the current search or filter.';
  String get editButton => _isArabic ? 'تعديل' : 'Edit';
  String get fleetDeactivateButton => _isArabic ? 'إلغاء التفعيل' : 'Deactivate';
  String get fleetReactivateButton => _isArabic ? 'إعادة التفعيل' : 'Reactivate';
  String get fleetDetailsButton => _isArabic ? 'التفاصيل' : 'Details';
  String get fleetBasicInfo => _isArabic ? 'البيانات الأساسية' : 'Basic information';
  String get fleetAccountability => _isArabic ? 'المسؤولية والمتابعة' : 'Accountability';
  String get fleetActivityTimeline => _isArabic ? 'سجل النشاط' : 'Activity timeline';
  String get fleetCreatedBy => _isArabic ? 'أنشأه' : 'Created by';
  String get fleetCreatedRole => _isArabic ? 'دور المنشئ' : 'Created role';
  String get fleetCreatedAt => _isArabic ? 'تاريخ الإنشاء' : 'Created at';
  String get fleetLastActivityBy => _isArabic ? 'آخر إجراء بواسطة' : 'Last activity by';
  String get fleetLastActivityRole => _isArabic ? 'دور آخر مستخدم' : 'Last activity role';
  String get fleetLastActivityAt => _isArabic ? 'وقت آخر إجراء' : 'Last activity at';
  String get fleetLoadingActivity => _isArabic ? 'جاري تحميل سجل النشاط...' : 'Loading activity...';
  String get fleetNoActivityFound => _isArabic ? 'لا يوجد نشاط مسجل لهذا الأصل.' : 'No activity found for this asset.';
  String get fleetUnknownUser => _isArabic ? 'مستخدم غير معروف' : 'Unknown user';
  String get fleetNotAvailable => _isArabic ? 'غير متاح' : 'Not available';
  String get fleetChanges => _isArabic ? 'التغييرات' : 'Changes';
  String get fleetConfirmDeactivateTitle => _isArabic ? 'تأكيد إلغاء التفعيل' : 'Confirm deactivation';
  String get fleetConfirmReactivateTitle => _isArabic ? 'تأكيد إعادة التفعيل' : 'Confirm reactivation';
  String get fleetConfirmDeactivateMessage => _isArabic ? 'هل تريد إلغاء تفعيل هذا الأصل؟' : 'Do you want to deactivate this asset?';
  String get fleetConfirmReactivateMessage => _isArabic ? 'هل تريد إعادة تفعيل هذا الأصل؟' : 'Do you want to reactivate this asset?';
  String get emptyValue => '-';

  String fleetDetailsTitle(String plateNumber) => _isArabic ? 'تفاصيل الأصل: $plateNumber' : 'Fleet asset details: $plateNumber';

  String vehicleStatusText(VehicleStatus status) {
    return switch (status) {
      VehicleStatus.available => _isArabic ? 'متاح' : 'Available',
      VehicleStatus.onTrip => _isArabic ? 'في رحلة' : 'On trip',
      VehicleStatus.loading => _isArabic ? 'تحميل' : 'Loading',
      VehicleStatus.unloading => _isArabic ? 'تفريغ' : 'Unloading',
      VehicleStatus.maintenance => _isArabic ? 'صيانة' : 'Maintenance',
      VehicleStatus.stopped => _isArabic ? 'متوقف' : 'Stopped',
      VehicleStatus.inactive => _isArabic ? 'غير نشط' : 'Inactive',
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
    if (key == 'status') return vehicleStatusText(VehicleStatusX.fromValue(text));
    return text;
  }
}
