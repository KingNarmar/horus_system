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

  String get tripTotalExpensesLabel =>
      _isArabic ? 'إجمالي المصروفات' : 'Total expenses';

  String get tripNetProfitHeader => _isArabic ? 'صافي الربح' : 'Net profit';

  String get tripStatusHeader => _isArabic ? 'الحالة' : 'Status';

  String get tripActionsHeader => _isArabic ? 'الإجراءات' : 'Actions';

  String get tripViewDetails => _isArabic ? 'عرض التفاصيل' : 'View details';

  String get tripUpdateStatus => _isArabic ? 'تحديث الحالة' : 'Update status';

  String get tripEmptyValue => '-';

  String get tripNotesLabel => _isArabic ? 'ملاحظات' : 'Notes';

  String get tripScheduledLoadingAtLabel =>
      _isArabic ? 'موعد التحميل المخطط' : 'Scheduled loading';

  String get tripScheduledDeliveryAtLabel =>
      _isArabic ? 'موعد التسليم المخطط' : 'Scheduled delivery';

  String get tripActualLoadingAtLabel =>
      _isArabic ? 'وقت التحميل الفعلي' : 'Actual loading';

  String get tripActualDeliveryAtLabel =>
      _isArabic ? 'وقت التسليم الفعلي' : 'Actual delivery';

  String get tripBasicInfo =>
      _isArabic ? 'البيانات الأساسية' : 'Basic information';

  String get tripAccountability => _isArabic ? 'المساءلة' : 'Accountability';

  String get tripActivityTimeline =>
      _isArabic ? 'سجل النشاط' : 'Activity timeline';

  String get tripStatusHistoryTitle =>
      _isArabic ? 'سجل حالات الرحلة' : 'Status history';

  String get tripLoadingActivity =>
      _isArabic ? 'جاري تحميل النشاط...' : 'Loading activity...';

  String get tripLoadingStatusHistory =>
      _isArabic ? 'جاري تحميل سجل الحالات...' : 'Loading status history...';

  String get tripNoActivityFound =>
      _isArabic ? 'لا يوجد نشاط بعد.' : 'No activity yet.';

  String get tripNoStatusHistoryFound =>
      _isArabic ? 'لا يوجد سجل حالات بعد.' : 'No status history yet.';

  String get tripCreatedBy => _isArabic ? 'تم الإنشاء بواسطة' : 'Created by';

  String get tripCreatedRole => _isArabic ? 'دور منشئ السجل' : 'Created role';

  String get tripCreatedAt => _isArabic ? 'وقت الإنشاء' : 'Created at';

  String get tripLastActivityBy =>
      _isArabic ? 'آخر نشاط بواسطة' : 'Last activity by';

  String get tripLastActivityRole =>
      _isArabic ? 'دور آخر نشاط' : 'Last activity role';

  String get tripLastActivityAt =>
      _isArabic ? 'وقت آخر نشاط' : 'Last activity at';

  String get tripUnknownUser => _isArabic ? 'مستخدم غير معروف' : 'Unknown user';

  String get tripChanges => _isArabic ? 'التغييرات' : 'Changes';

  String get tripCloseButton => _isArabic ? 'إغلاق' : 'Close';

  String get tripSaveButton => _isArabic ? 'حفظ' : 'Save';

  String get tripCancelButton => _isArabic ? 'إلغاء' : 'Cancel';

  String get tripRetryButton => _isArabic ? 'إعادة المحاولة' : 'Retry';

  String get tripNextStatusLabel =>
      _isArabic ? 'الحالة التالية' : 'Next status';

  String get tripStatusNotesLabel =>
      _isArabic ? 'ملاحظات تغيير الحالة' : 'Status change notes';

  String get tripNoAvailableStatusActions => _isArabic
      ? 'لا توجد حالات متاحة بعد الحالة الحالية.'
      : 'No available status actions for the current status.';

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

  String tripDetailsTitle(String name) {
    return _isArabic ? 'تفاصيل الرحلة: $name' : 'Trip details: $name';
  }

  String tripUpdateStatusTitle(String name) {
    return _isArabic ? 'تحديث حالة الرحلة: $name' : 'Update trip status: $name';
  }

  String tripCurrentStatusLine(String status) {
    return _isArabic ? 'الحالة الحالية: $status' : 'Current status: $status';
  }

  String tripStatusHistoryLine(String oldStatus, String newStatus) {
    return _isArabic
        ? 'من $oldStatus إلى $newStatus'
        : 'From $oldStatus to $newStatus';
  }

  String tripChangedByLine(String actor, String role, String dateTime) {
    return _isArabic
        ? '$actor ($role) - $dateTime'
        : '$actor ($role) - $dateTime';
  }

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

  String tripAuditActionLabel(String action) {
    return switch (action) {
      'created' => _isArabic ? 'تم الإنشاء' : 'Created',
      'updated' => _isArabic ? 'تم التعديل' : 'Updated',
      'status_changed' => _isArabic ? 'تم تغيير الحالة' : 'Status changed',
      'deactivated' => _isArabic ? 'تم إلغاء التفعيل' : 'Deactivated',
      'reactivated' => _isArabic ? 'تمت إعادة التفعيل' : 'Reactivated',
      _ => action,
    };
  }

  String tripAuditRoleLabel(String? role) {
    return switch (role) {
      'owner' => _isArabic ? 'مالك' : 'Owner',
      'admin' => _isArabic ? 'مدير' : 'Admin',
      'operations' => _isArabic ? 'تشغيل' : 'Operations',
      'accountant' => _isArabic ? 'محاسب' : 'Accountant',
      'viewer' => _isArabic ? 'مشاهد' : 'Viewer',
      'driver' => _isArabic ? 'سائق' : 'Driver',
      null || '' => tripEmptyValue,
      _ => role,
    };
  }

  String tripAuditTimelineHeader(String actor, String role, String dateTime) {
    return _isArabic
        ? '$actor ($role) - $dateTime'
        : '$actor ($role) - $dateTime';
  }

  String tripAuditChangeLine(String label, String oldValue, String newValue) {
    return _isArabic
        ? '$label: من $oldValue إلى $newValue'
        : '$label: from $oldValue to $newValue';
  }

  String tripAuditFieldLabel(String key) {
    return switch (key) {
      'customer_id' => tripCustomerHeader,
      'route_id' => tripRouteHeader,
      'driver_id' => tripDriverHeader,
      'tractor_head_id' => _isArabic ? 'رأس الجرار' : 'Tractor head',
      'trailer_id' => _isArabic ? 'المقطورة' : 'Trailer',
      'status' => tripStatusHeader,
      'loading_order_number' => tripLoadingOrderHeader,
      'waybill_number' => tripWaybillHeader,
      'quantity_tons' => tripQuantityHeader,
      'freight_price' => tripFreightPriceHeader,
      'total_expenses' => tripTotalExpensesLabel,
      'scheduled_loading_at' => tripScheduledLoadingAtLabel,
      'scheduled_delivery_at' => tripScheduledDeliveryAtLabel,
      'actual_loading_at' => tripActualLoadingAtLabel,
      'actual_delivery_at' => tripActualDeliveryAtLabel,
      'notes' => tripNotesLabel,
      'customer_name' => tripCustomerHeader,
      'route_name' => tripRouteHeader,
      'driver_name' => tripDriverHeader,
      'tractor_head_plate_number' =>
        _isArabic ? 'رقم رأس الجرار' : 'Tractor plate',
      'trailer_plate_number' => _isArabic ? 'رقم المقطورة' : 'Trailer plate',
      _ => key,
    };
  }

  String tripAuditValueLabel(String key, Object? value) {
    if (value == null) return tripEmptyValue;

    if (key == 'status' && value is String) {
      return tripStatusLabel(TripStatusX.fromValue(value));
    }

    return value.toString();
  }
}
