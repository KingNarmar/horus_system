abstract final class RouteDbErrorCodes {
  static const financialTermsPermissionDenied = 'P3431';
  static const readPermissionDenied = 'P3434';
  static const staleFinancialSnapshot = 'P3440';
  static const financialRateInvalid = 'P3441';
  static const financialRouteNotFound = 'P3442';
}

abstract final class RouteFinancialDbRpcs {
  static const setDefaultFreightRate = 'set_route_default_freight_rate_atomic';
}

abstract final class RouteFinancialDbRpcParams {
  static const companyId = 'p_company_id';
  static const routeId = 'p_route_id';
  static const rate = 'p_default_freight_rate';
  static const expectedUpdatedAt = 'p_expected_updated_at';
}
