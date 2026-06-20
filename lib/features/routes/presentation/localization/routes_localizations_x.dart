import '../../../../l10n/app_localizations.dart';

extension RoutesLocalizationsX on AppLocalizations {
  bool get _isArabic => localeName.startsWith('ar');

  String get routesTitle => _isArabic ? 'المسارات' : 'Routes';

  String get addRouteButton => _isArabic ? 'إضافة مسار' : 'Add route';

  String get addRouteTitle => _isArabic ? 'إضافة مسار' : 'Add route';

  String get editRouteTitle => _isArabic ? 'تعديل مسار' : 'Edit route';

  String get loadingLocationLabel =>
      _isArabic ? 'مكان التحميل' : 'Loading location';

  String get unloadingLocationLabel =>
      _isArabic ? 'مكان التفريغ' : 'Unloading location';

  String get governorateFromLabel =>
      _isArabic ? 'محافظة التحميل' : 'Loading governorate';

  String get governorateToLabel =>
      _isArabic ? 'محافظة التفريغ' : 'Unloading governorate';

  String get defaultFreightPriceLabel =>
      _isArabic ? 'سعر النقل الافتراضي' : 'Default freight price';

  String get routeNotesLabel => _isArabic ? 'ملاحظات' : 'Notes';

  String get loadingLocationRequired =>
      _isArabic ? 'مكان التحميل مطلوب.' : 'Loading location is required.';

  String get unloadingLocationRequired =>
      _isArabic ? 'مكان التفريغ مطلوب.' : 'Unloading location is required.';

  String get defaultFreightPriceInvalid => _isArabic
      ? 'أدخل رقم صحيح غير سالب.'
      : 'Enter a valid non-negative number.';

  String get searchRoutesHint =>
      _isArabic ? 'ابحث في المسارات' : 'Search routes';

  String get routesStatusAllFilter => _isArabic ? 'الكل' : 'All';

  String get routesStatusActiveFilter => _isArabic ? 'النشط' : 'Active';

  String get routesStatusInactiveFilter => _isArabic ? 'غير النشط' : 'Inactive';

  String get noRoutesFound =>
      _isArabic ? 'لا توجد مسارات.' : 'No routes found.';

  String get noRoutesMatchFilters => _isArabic
      ? 'لا توجد مسارات مطابقة للبحث أو الفلتر الحالي.'
      : 'No routes match the current search or filter.';

  String get routeDeactivateButton =>
      _isArabic ? 'إلغاء التفعيل' : 'Deactivate';

  String get routeReactivateButton =>
      _isArabic ? 'إعادة التفعيل' : 'Reactivate';

  String get confirmRouteDeactivateTitle =>
      _isArabic ? 'تأكيد إلغاء تفعيل المسار' : 'Confirm route deactivation';

  String get confirmRouteReactivateTitle =>
      _isArabic ? 'تأكيد إعادة تفعيل المسار' : 'Confirm route reactivation';

  String get confirmRouteDeactivateMessage => _isArabic
      ? 'هل تريد إلغاء تفعيل هذا المسار؟'
      : 'Do you want to deactivate this route?';

  String get confirmRouteReactivateMessage => _isArabic
      ? 'هل تريد إعادة تفعيل هذا المسار؟'
      : 'Do you want to reactivate this route?';

  String get routeLoadingHeader => _isArabic ? 'التحميل' : 'Loading';

  String get routeUnloadingHeader => _isArabic ? 'التفريغ' : 'Unloading';

  String get routeGovernoratesHeader =>
      _isArabic ? 'المحافظات' : 'Governorates';

  String get routeDefaultPriceHeader =>
      _isArabic ? 'السعر الافتراضي' : 'Default price';

  String get routeStatusHeader => _isArabic ? 'الحالة' : 'Status';

  String get activeStatusLabel => _isArabic ? 'نشط' : 'Active';

  String get inactiveStatusLabel => _isArabic ? 'غير نشط' : 'Inactive';

  String get editButton => _isArabic ? 'تعديل' : 'Edit';

  String get routeViewDetails => _isArabic ? 'عرض التفاصيل' : 'View details';

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
