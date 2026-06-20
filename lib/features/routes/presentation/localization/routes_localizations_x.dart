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

  String get emptyValue => '-';
}
