abstract final class DriverCompensationDbFields {
  static const String tableName = 'driver_compensation_revisions';

  static const String id = 'id';
  static const String companyId = 'company_id';
  static const String driverId = 'driver_id';
  static const String amountMinorUnits = 'amount_minor_units';
  static const String currencyCode = 'currency_code';
  static const String currencyFractionDigits = 'currency_fraction_digits';
  static const String effectiveFrom = 'effective_from';
  static const String effectiveTo = 'effective_to';
  static const String contractReference = 'contract_reference';
  static const String contractDocumentReference = 'contract_document_reference';
  static const String createdBy = 'created_by';
  static const String updatedBy = 'updated_by';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static const String allColumns =
      '$id,$companyId,$driverId,$amountMinorUnits,$currencyCode,'
      '$currencyFractionDigits,$effectiveFrom,$effectiveTo,'
      '$contractReference,$contractDocumentReference,$createdBy,$updatedBy,'
      '$createdAt,$updatedAt';
}
