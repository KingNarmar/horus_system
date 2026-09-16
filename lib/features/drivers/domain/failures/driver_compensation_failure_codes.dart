abstract final class DriverCompensationFailureCodes {
  static const String validationAmountPositive =
      'validation_driver_compensation_amount_positive';
  static const String validationCurrencyMismatch =
      'validation_driver_compensation_currency_mismatch';
  static const String validationEffectivePeriodInvalid =
      'validation_driver_compensation_effective_period_invalid';
  static const String validationContractReferenceInvalid =
      'validation_driver_compensation_contract_reference_invalid';
  static const String conflictOverlap =
      'conflict_driver_compensation_overlap';
  static const String conflictRevisionAlreadyEnded =
      'conflict_driver_compensation_revision_already_ended';
  static const String conflictDocumentAlreadyAttached =
      'conflict_driver_compensation_document_already_attached';
  static const String notFoundForDate =
      'not_found_driver_compensation_for_date';
  static const String notFoundRevision =
      'not_found_driver_compensation_revision';
  static const String notFoundDriver =
      'not_found_driver_compensation_driver';
  static const String notFoundDocument =
      'not_found_driver_compensation_document';
  static const String permissionView =
      'permission_driver_compensation_view';
  static const String permissionManage =
      'permission_driver_compensation_manage';
  static const String serverError = 'server_driver_compensation';
  static const String unexpectedError = 'unexpected_driver_compensation';
}
