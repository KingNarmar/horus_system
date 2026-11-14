abstract final class BusinessDocumentUploadRpc {
  static const reserve = 'reserve_business_document_upload';
  static const releaseByReference =
      'release_business_document_upload_by_reference';

  static const companyId = 'p_company_id';
  static const operationId = 'p_operation_id';
  static const bucketId = 'p_bucket_id';
  static const storageReference = 'p_storage_reference';
  static const replacesReference = 'p_replaces_reference';

  static const state = 'state';
  static const reserved = 'reserved';
}
