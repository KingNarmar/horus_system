abstract final class TripDbRpcs {
  static const create = 'create_trip_atomic';
  static const save = 'save_trip_atomic';
  static const updateStatus = 'update_trip_status_atomic';
}

abstract final class TripDbRpcParams {
  static const companyId = 'p_company_id';
  static const tripId = 'p_trip_id';
  static const customerId = 'p_customer_id';
  static const routeId = 'p_route_id';
  static const driverId = 'p_driver_id';
  static const tractorHeadId = 'p_tractor_head_id';
  static const trailerId = 'p_trailer_id';
  static const loadingOrderNumber = 'p_loading_order_number';
  static const waybillNumber = 'p_waybill_number';
  static const quantityTons = 'p_quantity_tons';
  static const agreedFreightRatePerTon = 'p_agreed_freight_rate_per_ton';
  static const commercialAmount = 'p_commercial_amount';
  static const scheduledLoadingAt = 'p_scheduled_loading_at';
  static const scheduledDeliveryAt = 'p_scheduled_delivery_at';
  static const actualLoadingAt = 'p_actual_loading_at';
  static const actualDeliveryAt = 'p_actual_delivery_at';
  static const notes = 'p_notes';
  static const newStatus = 'p_new_status';
}

abstract final class TripDbErrorCodes {
  static const managementPermissionDenied = 'P3410';
  static const statusPermissionDenied = 'P3411';
  static const notFound = 'P3412';
  static const temporalOrderInvalid = 'P3413';
  static const evidenceRequired = 'P3424';
  static const statusTransitionInvalid = 'P3426';
  static const checkViolation = '23514';
}

abstract final class TripDbConstraints {
  static const scheduledDeliveryNotBeforeLoading =
      'trips_scheduled_delivery_not_before_loading';
  static const actualDeliveryNotBeforeLoading =
      'trips_actual_delivery_not_before_loading';
}
