/// Company-owned Trip/Route reads with server-enforced role projections.
abstract final class AuthorizedBusinessRecordsDbRpcs {
  static const trips = 'get_authorized_trip_records';
  static const routes = 'get_authorized_route_records';
}

abstract final class AuthorizedBusinessRecordsDbParams {
  static const companyId = 'p_company_id';
  static const tripId = 'p_trip_id';
  static const routeId = 'p_route_id';
  static const activeOnly = 'p_active_only';
}
