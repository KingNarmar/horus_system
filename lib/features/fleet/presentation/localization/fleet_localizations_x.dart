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
  String get emptyValue => '-';

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
}
