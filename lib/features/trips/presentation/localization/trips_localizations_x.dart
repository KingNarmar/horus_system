import '../../../../core/errors/failure.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../expense_types/domain/entities/expense_type.dart';
import '../../../expenses/domain/entities/expense_funding_source.dart';
import '../../../expenses/domain/failures/expense_ledger_failure_codes.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_status_filter.dart';

extension TripsLocalizationsX on AppLocalizations {
  String get tripStatusHeader => statusHeader;
  String get tripActionsHeader => actionsHeader;
  String get tripNotesLabel => notesLabel;
  String get tripSaveButton => saveButton;
  String get tripCancelButton => cancelButton;
  String get tripRetryButton => retryButton;

  String get tripExpenseVoidedStatus => companyExpenseVoidedStatus;
  String get tripExpenseVoidButton => voidCompanyExpenseButton;
  String get tripExpenseVoidMessage => voidCompanyExpenseMessage;
  String get tripExpenseTypeAdminCosts => companyExpenseCategoryAdminCosts;
  String get tripExpenseTypeLicensesAndRenewals =>
      companyExpenseCategoryLicensesAndRenewals;
  String get tripExpenseTypeOfficeExpenses =>
      companyExpenseCategoryOfficeExpenses;
  String get tripExpenseTypeOilsAndFluids =>
      companyExpenseCategoryOilsAndFluids;
  String get tripExpenseTypeRent => companyExpenseCategoryRent;
  String get tripExpenseTypeSpareParts => companyExpenseCategorySpareParts;
  String get tripExpenseTypeTires => companyExpenseCategoryTires;
  String get tripExpenseTypeVehicleMaintenance =>
      companyExpenseCategoryVehicleMaintenance;

  String _bidiIsolate(String value) => '\u2068$value\u2069';

  String tripDetailsTitle(String name) {
    return tripDetailsTitleText(_bidiIsolate(name));
  }

  String tripUpdateStatusTitle(String name) {
    return tripUpdateStatusTitleText(_bidiIsolate(name));
  }

  String tripExpenseFundingSourceLabel(ExpenseFundingSource fundingSource) {
    return switch (fundingSource) {
      ExpenseFundingSource.company => tripExpensePaidByCompany,
      ExpenseFundingSource.driverAdvance => tripExpensePaidByDriverAdvance,
      ExpenseFundingSource.driverCash => tripExpensePaidByDriverCash,
      ExpenseFundingSource.customer => tripExpensePaidByCustomer,
      ExpenseFundingSource.other => tripExpensePaidByOther,
    };
  }

  String tripExpenseTypeDisplayLabel(ExpenseType expenseType) {
    return _tripExpenseTypeLabel(expenseType.code, expenseType.name);
  }

  String tripExpenseTypeName(String name) {
    final normalized = name.trim().toLowerCase().replaceAll(' ', '_');
    return _tripExpenseTypeLabel(normalized, name);
  }

  String _tripExpenseTypeLabel(String? code, String fallback) {
    return switch (code) {
      'admin_costs' => tripExpenseTypeAdminCosts,
      'emergency_maintenance' => tripExpenseTypeEmergencyMaintenance,
      'fines' => tripExpenseTypeFines,
      'fuel' => tripExpenseTypeFuel,
      'licenses_and_renewals' => tripExpenseTypeLicensesAndRenewals,
      'loading' => tripExpenseTypeLoading,
      'office_expenses' => tripExpenseTypeOfficeExpenses,
      'oils_and_fluids' => tripExpenseTypeOilsAndFluids,
      'other' => tripExpenseTypeOther,
      'rent' => tripExpenseTypeRent,
      'road_fees' => tripExpenseTypeRoadFees,
      'spare_parts' => tripExpenseTypeSpareParts,
      'tires' => tripExpenseTypeTires,
      'unloading' => tripExpenseTypeUnloading,
      'vehicle_maintenance' => tripExpenseTypeVehicleMaintenance,
      'weighbridge' => tripExpenseTypeWeighbridge,
      'driver_advance' => tripExpenseTypeDriverAdvance,
      _ => fallback,
    };
  }

  String tripExpenseFailureMessage(Failure failure) {
    return switch (failure.code) {
      ExpenseLedgerFailureCodes.permissionView =>
        failurePermissionTripExpensesView,
      ExpenseLedgerFailureCodes.permissionManage =>
        failurePermissionTripExpensesManagement,
      ExpenseLedgerFailureCodes.validationExpenseTypeRequired =>
        failureValidationTripExpenseTypeRequired,
      ExpenseLedgerFailureCodes.validationDescriptionRequired =>
        failureValidationTripExpenseNameRequired,
      ExpenseLedgerFailureCodes.validationAmountInvalid =>
        tripExpenseAmountPositive,
      ExpenseLedgerFailureCodes.validationAttributionInvalid =>
        failureValidationTripIdRequired,
      ExpenseLedgerFailureCodes.expenseTypeUnavailable =>
        tripExpenseTypesUnavailable,
      ExpenseLedgerFailureCodes.conflictAlreadyVoided =>
        tripExpenseVoidedStatus,
      ExpenseLedgerFailureCodes.serverError => failureServerError,
      ExpenseLedgerFailureCodes.unexpectedError => failureUnexpectedError,
      _ => failureUnexpectedError,
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
      'voided' => tripExpenseVoidedStatus,
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
      'expense_name' || 'description' => tripExpenseNameLabel,
      'expense_type_name' => tripExpenseTypeLabel,
      'amount' || 'amount_minor_units' => tripExpenseAmountLabel,
      'paid_by' || 'funding_source' => tripExpensePaidByLabel,
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

    if ((key == 'paid_by' || key == 'funding_source') && value is String) {
      return tripExpenseFundingSourceLabel(
        ExpenseFundingSourceX.fromValue(value),
      );
    }

    if ((key == 'expense_name' || key == 'expense_type_name') &&
        value is String) {
      return tripExpenseTypeName(value);
    }

    return value.toString();
  }
}
