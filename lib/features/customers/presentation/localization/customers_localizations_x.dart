import '../../../../l10n/app_localizations.dart';

extension CustomersLocalizationsX on AppLocalizations {
  bool get _isArabic => localeName.startsWith('ar');

  String get customerViewDetails => _isArabic ? 'التفاصيل' : 'Details';
  String get customerBasicInfo => _isArabic ? 'البيانات الأساسية' : 'Basic information';
  String get customerAccountability => _isArabic ? 'المسؤولية والمتابعة' : 'Accountability';
  String get customerActivityTimeline => _isArabic ? 'سجل النشاط' : 'Activity timeline';
  String get customerCreatedBy => _isArabic ? 'أنشأه' : 'Created by';
  String get customerCreatedRole => _isArabic ? 'دور المنشئ' : 'Created role';
  String get customerCreatedAt => _isArabic ? 'تاريخ الإنشاء' : 'Created at';
  String get customerLastActivityBy => _isArabic ? 'آخر إجراء بواسطة' : 'Last activity by';
  String get customerLastActivityRole => _isArabic ? 'دور آخر مستخدم' : 'Last activity role';
  String get customerLastActivityAt => _isArabic ? 'وقت آخر إجراء' : 'Last activity at';
  String get customerLoadingActivity => _isArabic ? 'جاري تحميل سجل النشاط...' : 'Loading activity...';
  String get customerNoActivityFound => _isArabic ? 'لا يوجد نشاط مسجل لهذا العميل.' : 'No activity found for this customer.';
  String get customerChanges => _isArabic ? 'التغييرات' : 'Changes';
  String get customerEmptyValue => _isArabic ? 'فارغ' : 'Empty';
  String get customerUnknownUser => _isArabic ? 'مستخدم غير معروف' : 'Unknown user';
  String get customerNotAvailable => _isArabic ? 'غير متاح' : 'Not available';

  String customerDetailsTitle(String name) {
    return _isArabic ? 'تفاصيل $name' : 'Customer details: $name';
  }

  String customerAuditActionLabel(String action) {
    return switch (action) {
      'created' => _isArabic ? 'تم الإنشاء' : 'Created',
      'updated' => _isArabic ? 'تم التعديل' : 'Updated',
      'deactivated' => _isArabic ? 'تم التعطيل' : 'Deactivated',
      'reactivated' => _isArabic ? 'تم التفعيل' : 'Reactivated',
      'status_changed' => _isArabic ? 'تم تغيير الحالة' : 'Status changed',
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
