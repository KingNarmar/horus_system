abstract final class TripFailureCodes {
  static const String notFound = 'trip_not_found';
  static const String financialTermsPermissionDenied =
      'permission_trip_financial_terms';
  static const String pricedQuantityRequiresFinance =
      'conflict_trip_priced_quantity_requires_finance';
  static const String financialCurrencyMismatch =
      'validation_trip_financial_currency_mismatch';
  static const String conflictStatusEvidenceRequired =
      'conflict_trip_status_required_evidence';
}
