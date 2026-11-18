abstract final class CompanyBrandingConstants {
  static const storageBucket = 'company-branding';
  static const storageRoot = 'companies';
  static const storageLogoFolder = 'logos';
  static const mimePng = 'image/png';
  static const mimeJpeg = 'image/jpeg';
  static const mimeWebp = 'image/webp';

  static const fetchCompanyProfile = 'companies';
  static const updateProfileRpc = 'update_company_brand_profile';
  static const reserveUploadRpc = 'reserve_company_branding_upload';
  static const releaseUploadRpc = 'release_company_branding_upload';
  static const setLogoRpc = 'set_company_brand_logo';

  static const companyIdArg = 'p_company_id';
  static const operationIdArg = 'p_operation_id';
  static const pathArg = 'p_storage_path';
  static const expectedUpdatedAtArg = 'p_expected_updated_at';
  static const expectedLogoArg = 'p_expected_logo_path';
  static const newLogoArg = 'p_new_logo_path';
  static const addressArg = 'p_address';
  static const registrationArg = 'p_tax_registration_number';
}
