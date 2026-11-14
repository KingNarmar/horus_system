/// Stable codes used across resource features; never expose raw SQL errors.
abstract final class QuotaFailureCodes {
  static const reached = 'quota_limit_reached';
  static const companyUsersReached = 'quota_company_users_reached';
  static const combinedVehiclesReached = 'quota_combined_vehicles_reached';
  static const customersReached = 'quota_customers_reached';
  static const driversReached = 'quota_drivers_reached';
  static const routesReached = 'quota_routes_reached';
  static const lifetimeTripsReached = 'quota_lifetime_trips_reached';
  static const lifetimeInvoicesReached = 'quota_lifetime_invoices_reached';
  static const businessDocumentsReached = 'quota_business_documents_reached';
  static const idempotencyPayloadConflict =
      'quota_idempotency_payload_conflict';
  static const idempotentRecordUnavailable =
      'quota_idempotent_record_unavailable';
  static const unavailable = 'quota_entitlement_unavailable';
  static const corrupt = 'quota_projection_invalid';
  static const permissionDenied = 'quota_permission_denied';
}
