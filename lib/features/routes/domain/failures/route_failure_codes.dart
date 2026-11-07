abstract final class RouteFailureCodes {
  static const staleFinancialSnapshot =
      'conflict_route_financial_snapshot_stale';
  static const notFound = 'route_financial_not_found';
  static const financialTermsPermissionDenied =
      'permission_route_financial_terms';
  static const financialRateRequiresSeparateAction =
      'conflict_route_rate_requires_separate_action';
}
