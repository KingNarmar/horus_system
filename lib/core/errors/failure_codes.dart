class FailureCodes {
  // Auth
  static const String authEmailRequired = 'auth_email_required';
  static const String authPasswordRequired = 'auth_password_required';
  static const String authFullNameRequired = 'auth_full_name_required';
  static const String authPhoneRequired = 'auth_phone_required';
  static const String authPasswordTooShort = 'auth_password_too_short';
  static const String authInvalidCredentials = 'auth_invalid_credentials';
  static const String authEmailNotConfirmed = 'auth_email_not_confirmed';
  static const String authAccountAlreadyExists = 'auth_account_already_exists';
  static const String authWeakPassword = 'auth_weak_password';
  static const String authInvalidEmail = 'auth_invalid_email';
  static const String authRateLimited = 'auth_rate_limited';
  static const String authError = 'auth_error';

  // Permissions
  static const String permissionDriversManagement =
      'permission_drivers_management';
  static const String permissionDriversView = 'permission_drivers_view';
  static const String permissionCustomersManagement =
      'permission_customers_management';
  static const String permissionCustomersView = 'permission_customers_view';
  static const String permissionCompanyUsersView =
      'permission_company_users_view';
  static const String permissionFleetManagement = 'permission_fleet_management';
  static const String permissionFleetView = 'permission_fleet_view';
  static const String permissionRoutesManagement =
      'permission_routes_management';
  static const String permissionRoutesView = 'permission_routes_view';
  static const String permissionTripsManagement = 'permission_trips_management';
  static const String permissionTripsView = 'permission_trips_view';
  static const String permissionTripStatusUpdate =
      'permission_trip_status_update';
  static const String permissionTripExpensesManagement =
      'permission_trip_expenses_management';
  static const String permissionTripExpensesView =
      'permission_trip_expenses_view';
  static const String permissionDriverFinanceManagement =
      'permission_driver_finance_management';
  static const String permissionDriverFinanceView =
      'permission_driver_finance_view';
  static const String permissionCompanyExpensesManagement =
      'permission_company_expenses_management';
  static const String permissionCompanyExpensesView =
      'permission_company_expenses_view';
  static const String permissionDriverSettlementsManagement =
      'permission_driver_settlements_management';
  static const String permissionDriverSettlementsView =
      'permission_driver_settlements_view';
  static const String permissionInvoicesManagement =
      'permission_invoices_management';
  static const String permissionInvoicesView = 'permission_invoices_view';
  static const String permissionInvoicesIssue = 'permission_invoices_issue';
  static const String permissionInvoicesCancel = 'permission_invoices_cancel';
  static const String permissionPaymentMethodsManagement =
      'permission_payment_methods_management';
  static const String permissionPaymentMethodsView =
      'permission_payment_methods_view';
  static const String permissionSubscriptionsView =
      'permission_subscriptions_view';

  // Validation
  static const String validationCompanyIdRequired =
      'validation_company_id_required';
  static const String validationDriverIdRequired =
      'validation_driver_id_required';
  static const String validationDriverNameRequired =
      'validation_driver_name_required';
  static const String validationDriverImageTooLarge =
      'validation_driver_image_too_large';
  static const String validationDriverImageTypeUnsupported =
      'validation_driver_image_type_unsupported';
  static const String validationCustomerNameRequired =
      'validation_customer_name_required';
  static const String validationCreditLimitNegative =
      'validation_credit_limit_negative';
  static const String validationCustomerIdRequired =
      'validation_customer_id_required';
  static const String validationCompanyNameRequired =
      'validation_company_name_required';
  static const String validationCompanyContextRequired =
      'validation_company_context_required';
  static const String validationAuditEntityIdRequired =
      'validation_audit_entity_id_required';
  static const String validationAuditDescriptionRequired =
      'validation_audit_description_required';
  static const String validationFleetPlateRequired =
      'validation_fleet_plate_required';
  static const String validationFleetFuelConsumptionNegative =
      'validation_fleet_fuel_consumption_negative';
  static const String validationRouteLoadingLocationRequired =
      'validation_route_loading_location_required';
  static const String validationRouteUnloadingLocationRequired =
      'validation_route_unloading_location_required';
  static const String validationRouteFreightPriceNegative =
      'validation_route_freight_price_negative';
  static const String validationTripIdRequired = 'validation_trip_id_required';
  static const String validationTripCustomerRequired =
      'validation_trip_customer_required';
  static const String validationTripRouteRequired =
      'validation_trip_route_required';
  static const String validationTripQuantityNegative =
      'validation_trip_quantity_negative';
  static const String validationTripFreightPriceNegative =
      'validation_trip_freight_price_negative';
  static const String validationTripExpensesNegative =
      'validation_trip_expenses_negative';
  static const String validationTripDeliveryBeforeLoading =
      'validation_trip_delivery_before_loading';
  static const String validationTripStatusTransitionInvalid =
      'validation_trip_status_transition_invalid';
  static const String validationTripExpenseIdRequired =
      'validation_trip_expense_id_required';
  static const String validationTripExpenseTypeRequired =
      'validation_trip_expense_type_required';
  static const String validationTripExpenseNameRequired =
      'validation_trip_expense_name_required';
  static const String validationTripExpenseAmountPositive =
      'validation_trip_expense_amount_positive';
  static const String validationDriverFinanceAmountPositive =
      'validation_driver_finance_amount_positive';
  static const String validationCompanyExpenseIdRequired =
      'validation_company_expense_id_required';
  static const String validationCompanyExpenseCategoryRequired =
      'validation_company_expense_category_required';
  static const String validationCompanyExpenseAmountPositive =
      'validation_company_expense_amount_positive';
  static const String validationDriverSettlementIdRequired =
      'validation_driver_settlement_id_required';
  static const String validationDriverSettlementPeriodInvalid =
      'validation_driver_settlement_period_invalid';
  static const String validationDriverSettlementAmountNegative =
      'validation_driver_settlement_amount_negative';
  static const String validationDriverSettlementNetSalaryNegative =
      'validation_driver_settlement_net_salary_negative';
  static const String validationDriverSettlementBalanceRecoveryExceedsDebt =
      'validation_driver_settlement_balance_recovery_exceeds_debt';
  static const String validationDriverSettlementDriverNotFound =
      'validation_driver_settlement_driver_not_found';
  static const String validationDriverSettlementDriverInactive =
      'validation_driver_settlement_driver_inactive';
  static const String validationDriverSettlementVoidReasonRequired =
      'validation_driver_settlement_void_reason_required';
  static const String validationInvoiceIdRequired =
      'validation_invoice_id_required';
  static const String validationInvoiceCustomerRequired =
      'validation_invoice_customer_required';
  static const String validationInvoiceTripsRequired =
      'validation_invoice_trips_required';
  static const String validationInvoiceSingleTripRequired =
      'validation_invoice_single_trip_required';
  static const String validationInvoiceGroupedTripsRequired =
      'validation_invoice_grouped_trips_required';
  static const String validationInvoiceDuplicateTrip =
      'validation_invoice_duplicate_trip';
  static const String validationInvoiceCurrencyInvalid =
      'validation_invoice_currency_invalid';
  static const String validationInvoiceCurrencyMismatch =
      'validation_invoice_currency_mismatch';
  static const String validationInvoiceIssueDateFuture =
      'validation_invoice_issue_date_future';
  static const String validationInvoiceDueDateBeforeIssue =
      'validation_invoice_due_date_before_issue';
  static const String validationInvoiceCancellationReasonRequired =
      'validation_invoice_cancellation_reason_required';
  static const String validationInvoiceLineAmountPositive =
      'validation_invoice_line_amount_positive';
  static const String validationInvoiceDiscountNegative =
      'validation_invoice_discount_negative';
  static const String validationInvoiceDiscountExceedsSubtotal =
      'validation_invoice_discount_exceeds_subtotal';
  static const String validationInvoiceTaxRateOutOfRange =
      'validation_invoice_tax_rate_out_of_range';
  static const String validationInvoiceTotalPositive =
      'validation_invoice_total_positive';
  static const String validationPaymentMethodIdRequired =
      'validation_payment_method_id_required';
  static const String validationPaymentMethodNameRequired =
      'validation_payment_method_name_required';
  static const String subscriptionStatusInvalid = 'subscription_status_invalid';

  // Not found
  static const String invoiceTripNotFound = 'invoice_trip_not_found';
  static const String paymentMethodNotFound = 'payment_method_not_found';

  // Conflicts
  static const String conflictTripVehicleAlreadyOpen =
      'conflict_trip_vehicle_already_open';
  static const String conflictInvoiceCustomerInactive =
      'conflict_invoice_customer_inactive';
  static const String conflictInvoiceCustomerCompanyMismatch =
      'conflict_invoice_customer_company_mismatch';
  static const String conflictInvoiceCustomerMismatch =
      'conflict_invoice_customer_mismatch';
  static const String conflictInvoiceTripCompanyMismatch =
      'conflict_invoice_trip_company_mismatch';
  static const String conflictInvoiceTripCustomerMismatch =
      'conflict_invoice_trip_customer_mismatch';
  static const String conflictInvoiceTripAlreadyInvoiced =
      'conflict_invoice_trip_already_invoiced';
  static const String conflictInvoiceTripNotBillable =
      'conflict_invoice_trip_not_billable';
  static const String conflictInvoiceStatusTransitionInvalid =
      'conflict_invoice_status_transition_invalid';
  static const String conflictInvoiceIssuedImmutable =
      'conflict_invoice_issued_immutable';
  static const String conflictInvoiceCustomerSnapshotChanged =
      'conflict_invoice_customer_snapshot_changed';
  static const String conflictInvoiceTripSnapshotChanged =
      'conflict_invoice_trip_snapshot_changed';
  static const String conflictInvoiceTotalsMismatch =
      'conflict_invoice_totals_mismatch';
  static const String conflictPaymentMethodDuplicateName =
      'conflict_payment_method_duplicate_name';

  // Generic
  static const String serverError = 'server_error';
  static const String unexpectedError = 'unexpected_error';
}
