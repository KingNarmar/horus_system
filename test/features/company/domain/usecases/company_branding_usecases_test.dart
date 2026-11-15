import 'dart:typed_data';

import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_brand_logo_file.dart';
import 'package:horus_system/features/company/domain/entities/company_brand_profile.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_branding_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_branding_repository.dart';
import 'package:horus_system/features/company/domain/usecases/download_company_brand_logo_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/update_company_brand_logo_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/update_company_brand_profile_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/validate_company_brand_logo_usecase.dart';
import 'package:test/test.dart';

void main() {
  test('owner updates only the current tenant profile after normalization',
      () async {
    final repository = _BrandingRepository();
    final useCase = UpdateCompanyBrandProfileUseCase(repository);
    final result = await useCase(UpdateCompanyBrandProfileParams(
      companyContext: _context(CompanyRole.owner),
      expectedUpdatedAt: DateTime.utc(2026, 11, 15),
      name: '  Example Hauling  ',
      city: '  Dubai  ',
      address: '  Warehouse Road  ',
    ));
    expect(result.failureOrNull, isNull);
    expect(repository.updateCount, 1);
    expect(repository.companyId, 'tenant-1');
    expect(repository.updatedName, 'Example Hauling');
    expect(repository.updatedCity, 'Dubai');
    expect(repository.updatedAddress, 'Warehouse Road');
  });

  test('viewer denied before any profile write', () async {
    final repository = _BrandingRepository();
    final result = await UpdateCompanyBrandProfileUseCase(repository)(
      UpdateCompanyBrandProfileParams(
        companyContext: _context(CompanyRole.viewer),
        expectedUpdatedAt: DateTime.utc(2026, 11, 15),
        name: 'Forbidden',
      ),
    );
    expect(result.failureOrNull?.code,
        CompanyBrandingFailureCodes.permissionDenied);
    expect(repository.updateCount, 0);
  });

  test('blank name rejected before repository access', () async {
    final repository = _BrandingRepository();
    final result = await UpdateCompanyBrandProfileUseCase(repository)(
      UpdateCompanyBrandProfileParams(
        companyContext: _context(CompanyRole.admin),
        expectedUpdatedAt: DateTime.utc(2026, 11, 15),
        name: '   ',
      ),
    );
    expect(result.failureOrNull?.code,
        CompanyBrandingFailureCodes.profileInvalid);
    expect(repository.updateCount, 0);
  });

  test('image validation prevents spoofed extension and oversized payloads',
      () async {
    const useCase = ValidateCompanyBrandLogoUseCase();
    final invalid = await useCase(CompanyBrandLogoFile(
      bytes: Uint8List.fromList([0, 1, 2]),
      fileName: 'logo.png',
    ));
    expect(invalid.failureOrNull?.code,
        CompanyBrandingFailureCodes.imageUnsupported);
    final oversize = await useCase(CompanyBrandLogoFile(
      bytes: Uint8List(2 * 1024 * 1024 + 1),
      fileName: 'logo.jpg',
    ));
    expect(oversize.failureOrNull?.code,
        CompanyBrandingFailureCodes.imageTooLarge);
    final valid = await useCase(CompanyBrandLogoFile(
      bytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
      fileName: 'logo.png',
    ));
    expect(valid.failureOrNull, isNull);
  });

  test('logo replacement and read reject foreign or unauthorized use',
      () async {
    final repository = _BrandingRepository();
    final image = CompanyBrandLogoFile(
      bytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
      fileName: 'logo.png',
    );
    final rejected = await UpdateCompanyBrandLogoUseCase(repository)(
      UpdateCompanyBrandLogoParams(
        companyContext: _context(CompanyRole.operations),
        expectedLogoPath: null,
        logo: image,
      ),
    );
    expect(rejected.failureOrNull?.code,
        CompanyBrandingFailureCodes.permissionDenied);
    expect(repository.uploadCount, 0);

    final accepted = await UpdateCompanyBrandLogoUseCase(repository)(
      UpdateCompanyBrandLogoParams(
        companyContext: _context(CompanyRole.admin),
        expectedLogoPath: null,
        logo: image,
      ),
    );
    expect(accepted.failureOrNull, isNull);
    expect(repository.uploadCount, 1);
    expect(repository.companyId, 'tenant-1');

    final read = await DownloadCompanyBrandLogoUseCase(repository)(
      const DownloadCompanyBrandLogoParams(
        companyId: 'tenant-1',
        path: 'companies/tenant-2/logos/foreign.png',
      ),
    );
    expect(read.failureOrNull?.code,
        CompanyBrandingFailureCodes.uploadInvalid);
    expect(repository.downloadCount, 0);
  });
}

CurrentCompanyContext _context(CompanyRole role) =>
    CurrentCompanyContext(
      company: const Company(id: 'tenant-1', name: 'Example'),
      role: role,
    );

final class _BrandingRepository implements CompanyBrandingRepository {
  int updateCount = 0;
  int uploadCount = 0;
  int downloadCount = 0;
  String? companyId;
  String? updatedName;
  String? updatedCity;
  String? updatedAddress;

  final profile = CompanyBrandProfile(
    companyId: 'tenant-1',
    name: 'Example',
    updatedAt: DateTime.utc(2026, 11, 15),
  );

  @override
  Future<Result<CompanyBrandProfile>> getProfile(String companyId) async =>
      Success(profile);

  @override
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
  }) async {
    updateCount++;
    this.companyId = companyId;
    updatedName = name;
    updatedCity = city;
    updatedAddress = address;
    return Success(profile);
  }

  @override
  Future<Result<CompanyBrandProfile>> updateLogo({
    required String companyId,
    required String? expectedLogoPath,
    required CompanyBrandLogoFile logo,
  }) async {
    uploadCount++;
    this.companyId = companyId;
    return Success(profile);
  }

  @override
  Future<Result<CompanyBrandProfile>> removeLogo({
    required String companyId,
    required String? expectedLogoPath,
  }) async => Success(profile);

  @override
  Future<Result<Uint8List>> downloadLogo({
    required String companyId,
    required String storagePath,
  }) async {
    downloadCount++;
    return Success(Uint8List(0));
  }
}
