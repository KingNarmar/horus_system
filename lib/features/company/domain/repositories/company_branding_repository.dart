import 'dart:typed_data';

import '../../../../core/utils/result.dart';
import '../entities/company_brand_logo_file.dart';
import '../entities/company_brand_profile.dart';

abstract class CompanyBrandingRepository {
  Future<Result<CompanyBrandProfile>> getProfile(String companyId);

  Future<Result<CompanyBrandProfile>> updateProfile({
    required String companyId,
    required DateTime expectedUpdatedAt,
    required String name,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
    String? address,
    String? taxRegistrationNumber,
  });

  Future<Result<CompanyBrandProfile>> updateLogo({
    required String companyId,
    required String? expectedLogoPath,
    required CompanyBrandLogoFile logo,
  });

  Future<Result<CompanyBrandProfile>> removeLogo({
    required String companyId,
    required String? expectedLogoPath,
  });

  Future<Result<Uint8List>> downloadLogo({
    required String companyId,
    required String storagePath,
  });
}
