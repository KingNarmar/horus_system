import '../../../../l10n/app_localizations.dart';
import '../../../expenses/domain/entities/trip_expense_paid_by.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_status_filter.dart';

extension TripsLocalizationsX on AppLocalizations {
  String get tripStatusHeader => statusHeader;
  String get tripActionsHeader => actionsHeader;
  String get tripNotesLabel => notesLabel;
  String get tripSaveButton => saveButton;
  String get tripCancelButton => cancelButton;
  String get tripRetryButton => retryButton;

  String _bidiIsolate(String value) => '\u2068$value\u2069';

  String tripDetailsTitle(String name) {
    return tripDetailsTitleText(_bidiIsolate(name));
  }

  String tripUpdateStatusTitle(String name) {
    return tripUpdateStatusTitleText(_bidiIsolate(name));
  }

  String tripExpensePaidByValueLabel(TripExpensePaidBy paidBy) {
    return switch (paidBy) {
      TripExpensePaidBy.company => tripExpensePaidByCompany,
      TripExpensePaidBy.driverAdvance => tripExpensePaidByDriverAdvance,
      TripExpensePaidBy.driverCash => tripExpensePaidByDriverCash,
      TripExpensePaidBy.customer => tripExpensePaidByCustomer,
      TripExpensePaidBy.other => tripExpensePaidByOther,
    };
  }

  String tripExpenseTypeName(String name) {
    final normalized = name.trim().toLowerCase().replaceAll(' ', '_');

    return switch (normalized) {
      'fuel' => tripExpenseTypeFuel,
      'road_fees' => tripExpenseTypeRoadFees,
      'weighbridge' => tripExpenseTypeWeighbridge,
      'loading' => tripExpenseTypeLoading,
      'unloading' => tripExpenseTypeUnloading,
      'fines' => tripExpenseTypeFines,
      'emergency_maintenance' => tripExpenseTypeEmergencyMaintenance,
      'driver_advance' => tripExpenseTypeDriverAdvance,
      'other' => tripExpenseTypeOther,
      _ => name,
    };
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
      'created' => tripAuditActionCreated,
      'updated' => tripAuditActionUpdated,
      'status_changed' => tripAuditActionStatusChanged,
      'deactivated' => tripAuditActionDeactivated,
      'reactivated' => tripAuditActionReactivated,
      _ => action,
    };
  }

  String tripAuditRoleLabel(String? role) {
    return switch (role) {
      'owner' => tripAuditRoleOwner,
      'admin' => tripAuditRoleAdmin,
      'operations' => tripAuditRoleOperations,
      'accountant' => tripAuditRoleAccountant,
      'viewer' => tripAuditRoleViewer,
      'driver' => tripAuditRoleDriver,
      null || '' => tripEmptyValue,
      _ => role,
    };
  }

  String tripAuditFieldLabel(String key) {
    return switch (key) {
      'customer_id' => tripCustomerHeader,
      'route_id' => tripRouteHeader,
      'driver_id' => tripDriverHeader,
      'tractor_head_id' => tripTractorHeadLabel,
      'trailer_id' => tripTrailerLabel,
      'status' => tripStatusHeader,
      'loading_order_number' => tripLoadingOrderHeader,
      'waybill_number' => tripWaybillHeader,
      'quantity_tons' => tripQuantityHeader,
      'freight_price' => tripFreightPriceHeader,
      'total_expenses' => tripTotalExpensesLabel,
      'trip_total_expenses' => tripTotalExpensesLabel,
      'expense_id' => tripAuditFieldExpenseId,
      'expense_type_id' => tripExpenseTypeLabel,
      'expense_name' => tripExpenseNameLabel,
      'expense_type_name' => tripExpenseTypeLabel,
      'amount' => tripExpenseAmountLabel,
      'paid_by' => tripExpensePaidByLabel,
      'expense_date' => tripExpenseDateLabel,
      'scheduled_loading_at' => tripScheduledLoadingAtLabel,
      'scheduled_delivery_at' => tripScheduledDeliveryAtLabel,
      'actual_loading_at' => tripActualLoadingAtLabel,
      'actual_delivery_at' => tripActualDeliveryAtLabel,
      'notes' => tripNotesLabel,
      'customer_name' => tripCustomerHeader,
      'route_name' => tripRouteHeader,
      'driver_name' => tripDriverHeader,
      'tractor_head_plate_number' => tripAuditFieldTractorPlate,
      'trailer_plate_number' => tripAuditFieldTrailerPlate,
      _ => key,
    };
  }

  String tripAuditValueLabel(String key, Object? value) {
    if (value == null) return tripEmptyValue;

    if (key == 'status' && value is String) {
      return tripStatusLabel(TripStatusX.fromValue(value));
    }

    if (key == 'paid_by' && value is String) {
      return tripExpensePaidByValueLabel(TripExpensePaidByX.fromValue(value));
    }

    if ((key == 'expense_name' || key == 'expense_type_name') &&
        value is String) {
      return tripExpenseTypeName(value);
    }

    return value.toString();
  }
}
