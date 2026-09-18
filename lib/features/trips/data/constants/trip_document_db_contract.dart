import '../../../../core/data/constants/db_common_fields.dart';

abstract final class TripDocumentDbFields {
  static const tableName = 'trip_documents';

  static const tripId = 'trip_id';
  static const documentKind = 'document_kind';
  static const storageReference = 'storage_reference';
  static const originalFileName = 'original_file_name';
  static const mimeType = 'mime_type';
  static const sizeBytes = 'size_bytes';
  static const uploadedBy = 'uploaded_by';
  static const uploadedAt = 'uploaded_at';
  static const removedBy = 'removed_by';
  static const removedAt = 'removed_at';
  static const replacesDocumentId = 'replaces_document_id';

  static const allColumns =
      '${DbCommonFields.id}, ${DbCommonFields.companyId}, $tripId, '
      '$documentKind, $storageReference, '
      '$originalFileName, $mimeType, $sizeBytes, $uploadedBy, $uploadedAt, '
      '$removedBy, $removedAt, $replacesDocumentId';
}

abstract final class TripDocumentDbRpcs {
  static const create = 'create_trip_document_atomic';
  static const replace = 'replace_trip_document_atomic';
  static const remove = 'remove_trip_document_atomic';
}

abstract final class TripDocumentDbRpcParams {
  static const companyId = 'p_company_id';
  static const tripId = 'p_trip_id';
  static const documentId = 'p_document_id';
  static const documentKind = 'p_document_kind';
  static const storageReference = 'p_storage_reference';
  static const originalFileName = 'p_original_file_name';
  static const mimeType = 'p_mime_type';
  static const sizeBytes = 'p_size_bytes';
}

abstract final class TripDocumentDbErrorCodes {
  static const permissionDenied = 'P3420';
  static const tripNotFound = 'P3421';
  static const documentNotFound = 'P3422';
  static const maxActiveDocuments = 'P3423';
  static const evidenceRequired = 'P3424';
  static const invalidStorageReference = 'P3425';
  static const invalidStatusTransition = 'P3426';
}
