import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_status_filter.dart';

extension TripsLocalizationsX on AppLocalizations {
  bool get _isArabic => localeName.startsWith('ar');

  String get tripsTitle => _isArabic ? 'الرحلات' : 'Trips';

  String get addTripButton => _isArabic ? 'إضافة رحلة' : 'Add trip';

  String get addTripTitle => _isArabic ? 'إضافة رحلة' : 'Add trip';

  String get editTripTitle => _isArabic ? 'تعديل رحلة' : 'Edit trip';

  String get searchTripsHint => _isArabic ? 'ابحث في الرحلات' : 'Search trips';

  String get noTripsFound => _isArabic ? 'لا توجد رحلات.' : 'No trips found.';

  String get noTripsMatchFilters => _isArabic
      ? 'لا توجد رحلات مطابقة للبحث أو الفلتر الحالي.'
      : 'No trips match the current search or filter.';

  String get tripCustomerHeader => _isArabic ? 'العميل' : 'Customer';

  String get tripRouteHeader => _isArabic ? 'المسار' : 'Route';

  String get tripDriverHeader => _isArabic ? 'السائق' : 'Driver';

  String get tripVehicleHeader => _isArabic ? 'المركبة' : 'Vehicle';

  String get tripLoadingOrderHeader =>
      _isArabic ? 'أمر التحميل' : 'Loading order';

  String get tripWaybillHeader => _isArabic ? 'رقم البوليصة' : 'Waybill';

  String get tripQuantityHeader => _isArabic ? 'الكمية' : 'Quantity';

  String get tripTonsSuffix => _isArabic ? 'طن' : 't';

  String get tripFreightPriceHeader => _isArabic ? 'سعر النقل' : 'Freight';

  String get tripNetProfitHeader => _isArabic ? 'صافي الربح' : 'Net profit';

  String get tripStatusHeader => _isArabic ? 'الحالة' : 'Status';

  String get tripActionsHeader => _isArabic ? 'الإجراءات' : 'Actions';

  String get tripViewDetails => _isArabic ? 'عرض التفاصيل' : 'View details';

  String get tripUpdateStatus => _isArabic ? 'تحديث الحالة' : 'Update status';

  String get tripEmptyValue => '-';

  String get tripsStatusAllFilter => _isArabic ? 'الكل' : 'All';

  String get tripsStatusOpenFilter => _isArabic ? 'المفتوحة' : 'Open';

  String get tripsStatusCreatedFilter => _isArabic ? 'جديدة' : 'Created';

  String get tripsStatusAssignedFilter => _isArabic ? 'مخصصة' : 'Assigned';

  String get tripsStatusLoadedFilter => _isArabic ? 'تم التحميل' : 'Loaded';

  String get tripsStatusOnRoadFilter => _isArabic ? 'على الطريق' : 'On road';

  String get tripsStatusArrivedFilter => _isArabic ? 'وصلت' : 'Arrived';

  String get tripsStatusDeliveredFilter =>
      _isArabic ? 'تم التسليم' : 'Delivered';

  String get tripsStatusDocumentsReceivedFilter =>
      _isArabic ? 'تم استلام المستندات' : 'Documents received';

  String get tripsStatusInvoicedFilter =>
      _isArabic ? 'تمت الفوترة' : 'Invoiced';

  String get tripsStatusPaidFilter => _isArabic ? 'مدفوعة' : 'Paid';

  String get tripsStatusCancelledFilter => _isArabic ? 'ملغاة' : 'Cancelled';

  String tripStatusFilterLabel(TripStatusFilter filter) {
    return switch (filter) {
      TripStatusFilter.all => tripsStatusAllFilter,
      TripStatusFilter.open => tripsStatusOpenFilter,
      TripStatusFilter.created => tripsStatusCreatedFilter,
      TripStatusFilter.assigned => tripsStatusAssignedFilter,
      TripStatusFilter.loaded => tripsStatusLoadedFilter,
      TripStatusFilter.onRoad => tripsStatusOnRoadFilter,
      TripStatusFilter.arrived => tripsStatusArrivedFilter,
      TripStatusFilter.delivered => tripsStatusDeliveredFilter,
      TripStatusFilter.documentsReceived => tripsStatusDocumentsReceivedFilter,
      TripStatusFilter.invoiced => tripsStatusInvoicedFilter,
      TripStatusFilter.paid => tripsStatusPaidFilter,
      TripStatusFilter.cancelled => tripsStatusCancelledFilter,
    };
  }

  String tripStatusLabel(TripStatus status) {
    return switch (status) {
      TripStatus.created => tripsStatusCreatedFilter,
      TripStatus.assigned => tripsStatusAssignedFilter,
      TripStatus.loaded => tripsStatusLoadedFilter,
      TripStatus.onRoad => tripsStatusOnRoadFilter,
      TripStatus.arrived => tripsStatusArrivedFilter,
      TripStatus.delivered => tripsStatusDeliveredFilter,
      TripStatus.documentsReceived => tripsStatusDocumentsReceivedFilter,
      TripStatus.invoiced => tripsStatusInvoicedFilter,
      TripStatus.paid => tripsStatusPaidFilter,
      TripStatus.cancelled => tripsStatusCancelledFilter,
    };
  }
}
