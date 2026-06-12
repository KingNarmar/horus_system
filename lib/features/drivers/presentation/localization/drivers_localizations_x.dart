import '../../../../l10n/app_localizations.dart';

extension DriversLocalizationsX on AppLocalizations {
  bool get _isArabic => localeName.startsWith('ar');

  String get driversTitle => _isArabic ? 'السائقون' : 'Drivers';
  String get addDriverButton => _isArabic ? 'إضافة سائق' : 'Add Driver';
  String get editDriverButton => _isArabic ? 'تعديل' : 'Edit';
  String get deactivateDriverButton => _isArabic ? 'إيقاف' : 'Deactivate';
  String get reactivateDriverButton => _isArabic ? 'إعادة تفعيل' : 'Reactivate';
  String get viewDriverDetails => _isArabic ? 'عرض التفاصيل' : 'View details';
  String get driverDetails => _isArabic ? 'تفاصيل السائق' : 'Driver details';
  String get searchDriversHint => _isArabic
      ? 'ابحث بالاسم أو الهاتف أو الرقم القومي أو الرخصة'
      : 'Search by name, phone, national ID, or license';
  String get driversStatusAllFilter => _isArabic ? 'الكل' : 'All';
  String get driversStatusActiveFilter => _isArabic ? 'النشط' : 'Active';
  String get driversStatusInactiveFilter => _isArabic ? 'غير النشط' : 'Inactive';
  String get noDriversFound => _isArabic ? 'لا يوجد سائقون.' : 'No drivers found.';
  String get noDriversMatchFilters => _isArabic
      ? 'لا يوجد سائقون مطابقون للبحث أو فلتر الحالة الحالي.'
      : 'No drivers match the current search or status filter.';
  String get driverNameLabel => _isArabic ? 'اسم السائق' : 'Driver name';
  String get driverNameRequired => _isArabic ? 'اسم السائق مطلوب.' : 'Driver name is required.';
  String get nationalIdLabel => _isArabic ? 'الرقم القومي' : 'National ID';
  String get licenseNumberLabel => _isArabic ? 'رقم الرخصة' : 'License number';
  String get licenseExpiryDateLabel => _isArabic ? 'تاريخ انتهاء الرخصة' : 'License expiry date';
  String get notesLabel => _isArabic ? 'ملاحظات' : 'Notes';
  String get saveButton => _isArabic ? 'حفظ' : 'Save';
  String get basicInfo => _isArabic ? 'البيانات الأساسية' : 'Basic information';
  String get accountability => _isArabic ? 'المسؤولية' : 'Accountability';
  String get activityTimeline => _isArabic ? 'سجل النشاط' : 'Activity timeline';
  String get createdBy => _isArabic ? 'تم الإنشاء بواسطة' : 'Created by';
  String get createdRole => _isArabic ? 'الدور وقت الإنشاء' : 'Created role';
  String get createdAt => _isArabic ? 'تاريخ الإنشاء' : 'Created at';
  String get lastActivityBy => _isArabic ? 'آخر نشاط بواسطة' : 'Last activity by';
  String get lastActivityRole => _isArabic ? 'دور آخر نشاط' : 'Last activity role';
  String get lastActivityAt => _isArabic ? 'وقت آخر نشاط' : 'Last activity at';
  String get loadingActivity => _isArabic ? 'جاري تحميل النشاط...' : 'Loading activity...';
  String get noActivityFound => _isArabic ? 'لا يوجد نشاط بعد.' : 'No activity yet.';
  String get emptyValue => '-';
  String get unknownUser => _isArabic ? 'مستخدم غير معروف' : 'Unknown user';
  String get notAvailable => _isArabic ? 'غير متاح' : 'Not available';

  String driverDetailsTitle(String name) => _isArabic ? 'تفاصيل السائق: $name' : 'Driver details: $name';

  String auditActionLabel(String action) {
    return switch (action) {
      'created' => _isArabic ? 'تم الإنشاء' : 'Created',
      'updated' => _isArabic ? 'تم التحديث' : 'Updated',
      'deactivated' => _isArabic ? 'تم الإيقاف' : 'Deactivated',
      'reactivated' => _isArabic ? 'تمت إعادة التفعيل' : 'Reactivated',
      _ => action,
    };
  }

  String driverFieldLabel(String field) {
    return switch (field) {
      'full_name' => driverNameLabel,
      'phone' => _isArabic ? 'الهاتف' : 'Phone',
      'national_id' => nationalIdLabel,
      'license_number' => licenseNumberLabel,
      'license_expiry_date' => licenseExpiryDateLabel,
      'notes' => notesLabel,
      'is_active' => _isArabic ? 'الحالة' : 'Status',
      _ => field,
    };
  }

  String driverValueLabel(String field, Object? value) {
    if (field == 'is_active') {
      return value == true
          ? (_isArabic ? 'نشط' : 'Active')
          : (_isArabic ? 'غير نشط' : 'Inactive');
    }
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? emptyValue : text;
  }
}
