import '../../../../core/data/constants/db_common_fields.dart';

abstract final class FleetLicenseDocumentDbFields {
  static const tableName = 'fleet_license_documents';

  static const tractorHeadId = 'tractor_head_id';
  static const trailerId = 'trailer_id';
  static const uploadedBy = 'uploaded_by';
  static const uploadedAt = 'uploaded_at';
  static const removedBy = 'removed_by';
  static const removedAt = 'removed_at';
  static const replacesDocumentId = 'replaces_document_id';

  static const allColumns =
      '${DbCommonFields.id}, ${DbCommonFields.companyId}, $tractorHeadId, '
      '$trailerId, $uploadedBy, $uploadedAt, $removedBy, $removedAt, '
      '$replacesDocumentId';
}

abstract final class FleetLicenseDocumentFileDbFields {
  static const tableName = 'fleet_license_document_files';

  static const licenseDocumentId = 'license_document_id';
  static const side = 'side';
  static const storageReference = 'storage_reference';
  static const originalFileName = 'original_file_name';
  static const mimeType = 'mime_type';
  static const sizeBytes = 'size_bytes';
  static const uploadedBy = 'uploaded_by';
  static const uploadedAt = 'uploaded_at';
  static const removedBy = 'removed_by';
  static const removedAt = 'removed_at';
  static const replacesFileId = 'replaces_file_id';

  static const allColumns =
      '${DbCommonFields.id}, ${DbCommonFields.companyId}, $licenseDocumentId, '
      '$side, $storageReference, $originalFileName, $mimeType, $sizeBytes, '
      '$uploadedBy, $uploadedAt, $removedBy, $removedAt, $replacesFileId';
}

abstract final class FleetLicenseDocumentDbRpcs {
  static const create = 'create_fleet_license_document_atomic';
  static const addFile = 'add_fleet_license_document_file_atomic';
  static const replaceFile = 'replace_fleet_license_document_file_atomic';
  static const remove = 'remove_fleet_license_document_atomic';
}

abstract final class FleetLicenseDocumentDbRpcParams {
  static const companyId = 'p_company_id';
  static const assetType = 'p_asset_type';
  static const assetId = 'p_asset_id';
  static const documentId = 'p_document_id';
  static const fileId = 'p_file_id';
  static const fileSide = 'p_file_side';
  static const storageReference = 'p_storage_reference';
  static const originalFileName = 'p_original_file_name';
  static const mimeType = 'p_mime_type';
  static const sizeBytes = 'p_size_bytes';
  static const licenseExpiryDate = 'p_license_expiry_date';
}

abstract final class FleetLicenseDocumentDbErrorCodes {
  static const permissionDenied = 'P3430';
  static const assetNotFound = 'P3431';
  static const documentNotFound = 'P3432';
  static const activeDocumentExists = 'P3433';
  static const invalidStorageReference = 'P3434';
  static const invalidAssetType = 'P3435';
  static const fileSideConflict = 'P3436';
  static const fileNotFound = 'P3437';
  static const invalidFileSide = 'P3438';
}
