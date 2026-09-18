abstract final class TripDocumentFailureCodes {
  static const permissionView = 'permission_trip_documents_view';
  static const permissionManage = 'permission_trip_documents_manage';
  static const validationDocumentIdRequired =
      'validation_trip_document_id_required';
  static const validationDocumentKindRequired =
      'validation_trip_document_kind_required';
  static const conflictMaxActiveDocuments =
      'conflict_trip_documents_max_active';
  static const conflictEvidenceRequired =
      'conflict_trip_documents_required_evidence';
  static const notFound = 'trip_document_not_found';
  static const compensationCleanupFailed =
      'trip_document_compensation_cleanup_failed';
  static const serverError = 'trip_document_server_error';
  static const unexpectedError = 'trip_document_unexpected_error';
}
