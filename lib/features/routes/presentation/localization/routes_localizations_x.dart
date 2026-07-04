import '../../../../l10n/app_localizations.dart';

extension RoutesLocalizationsX on AppLocalizations {
  bool get _isArabic => localeName.startsWith('ar');

  String get activeStatusLabel => routeActiveStatusLabel;

  String get inactiveStatusLabel => routeInactiveStatusLabel;

  String get editButton => routeEditButton;

  String routeDetailsTitle(String name) {
    return _isArabic ? 'تفاصيل المسار: $name' : 'Route details: $name';
  }

  String get routeBasicInfo =>
      _isArabic ? 'البيانات الأساسية' : 'Basic information';

  String get routeAccountability => _isArabic ? 'المساءلة' : 'Accountability';

  String get routeCreatedBy => _isArabic ? 'تم الإنشاء بواسطة' : 'Created by';

  String get routeCreatedRole => _isArabic ? 'دور منشئ السجل' : 'Created role';

  String get routeCreatedAt => _isArabic ? 'وقت الإنشاء' : 'Created at';

  String get routeLastActivityBy =>
      _isArabic ? 'آخر نشاط بواسطة' : 'Last activity by';

  String get routeLastActivityRole =>
      _isArabic ? 'دور آخر نشاط' : 'Last activity role';

  String get routeLastActivityAt =>
      _isArabic ? 'وقت آخر نشاط' : 'Last activity at';

  String get routeActivityTimeline =>
      _isArabic ? 'سجل النشاط' : 'Activity timeline';

  String get routeLoadingActivity =>
      _isArabic ? 'جاري تحميل النشاط...' : 'Loading activity...';

  String get routeNoActivityFound =>
      _isArabic ? 'لا يوجد نشاط بعد.' : 'No activity yet.';

  String get routeChanges => _isArabic ? 'التغييرات' : 'Changes';

  String get routeUnknownUser =>
      _isArabic ? 'مستخدم غير معروف' : 'Unknown user';

  String get routeNotAvailable => _isArabic ? 'غير متاح' : 'N/A';

  String get routeEmptyValue => '-';

  String get emptyValue => '-';

  String routeAuditActionLabel(String action) {
    return switch (action) {
      'created' => _isArabic ? 'تم الإنشاء' : 'Created',
      'updated' => _isArabic ? 'تم التعديل' : 'Updated',
      'deactivated' => _isArabic ? 'تم إلغاء التفعيل' : 'Deactivated',
      'reactivated' => _isArabic ? 'تمت إعادة التفعيل' : 'Reactivated',
      'status_changed' => _isArabic ? 'تم تغيير الحالة' : 'Status changed',
      _ => action,
    };
  }

  String routeAuditRoleLabel(String? role) {
    return switch (role) {
      'owner' => _isArabic ? 'مالك' : 'Owner',
      'admin' => _isArabic ? 'مدير' : 'Admin',
      'operations' => _isArabic ? 'تشغيل' : 'Operations',
      'accountant' => _isArabic ? 'محاسب' : 'Accountant',
      'viewer' => _isArabic ? 'مشاهد' : 'Viewer',
      'driver' => _isArabic ? 'سائق' : 'Driver',
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

  String routeAuditTimelineHeader(String actor, String role, String dateTime) {
    return _isArabic
        ? '$actor ($role) - $dateTime'
        : '$actor ($role) - $dateTime';
  }

  String routeAuditChangeLine(String label, String oldValue, String newValue) {
    return _isArabic
        ? '$label: من $oldValue إلى $newValue'
        : '$label: from $oldValue to $newValue';
  }
}
