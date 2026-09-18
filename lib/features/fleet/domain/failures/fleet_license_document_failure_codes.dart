abstract final class FleetLicenseDocumentFailureCodes {
  static const permissionView = 'permission_fleet_license_documents_view';
  static const permissionManage = 'permission_fleet_license_documents_manage';
  static const validationAssetIdRequired =
      'validation_fleet_license_document_asset_id_required';
  static const validationDocumentIdRequired =
      'validation_fleet_license_document_id_required';
  static const validationFileIdRequired =
      'validation_fleet_license_document_file_id_required';
  static const conflictActiveDocumentExists =
      'conflict_fleet_license_document_active_exists';
  static const conflictFileSide = 'conflict_fleet_license_document_file_side';
  static const notFound = 'fleet_license_document_not_found';
  static const fileNotFound = 'fleet_license_document_file_not_found';
  static const compensationCleanupFailed =
      'fleet_license_document_compensation_cleanup_failed';
  static const serverError = 'fleet_license_document_server_error';
  static const unexpectedError = 'fleet_license_document_unexpected_error';
}
