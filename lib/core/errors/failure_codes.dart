class FailureCodes {
  // Auth
  static const String authEmailRequired = 'auth_email_required';
  static const String authPasswordRequired = 'auth_password_required';
  static const String authFullNameRequired = 'auth_full_name_required';
  static const String authPhoneRequired = 'auth_phone_required';
  static const String authPasswordTooShort = 'auth_password_too_short';

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

  // Validation
  static const String validationCompanyIdRequired =
      'validation_company_id_required';
  static const String validationDriverNameRequired =
      'validation_driver_name_required';
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
  static const String validationTripExpenseNameRequired =
      'validation_trip_expense_name_required';
  static const String validationTripExpenseAmountPositive =
      'validation_trip_expense_amount_positive';

  // Conflicts
  static const String conflictTripVehicleAlreadyOpen =
      'conflict_trip_vehicle_already_open';

  // Generic
  static const String serverError = 'server_error';
  static const String unexpectedError = 'unexpected_error';
}
