abstract final class TripFailureCodes {
  static const String notFound = 'trip_not_found';
  static const String financialTermsPermissionDenied =
      'permission_trip_financial_terms';
  static const String pricedQuantityRequiresFinance =
      'conflict_trip_priced_quantity_requires_finance';
  static const String pricingRequiresQuantity =
      'conflict_trip_pricing_requires_quantity';
  static const String invoicedFinancialTermsLocked =
      'conflict_trip_invoiced_financial_terms_locked';
  static const String staleFinancialSnapshot =
      'conflict_trip_financial_snapshot_stale';
  static const String concurrentModification =
      'conflict_trip_modified_elsewhere';
  static const String financialCurrencyMismatch =
      'validation_trip_financial_currency_mismatch';
  static const String conflictStatusEvidenceRequired =
      'conflict_trip_status_required_evidence';
}
