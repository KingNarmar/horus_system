import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_brand_logo_file.dart';
import 'package:horus_system/features/company/domain/entities/company_brand_profile.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/repositories/company_branding_repository.dart';
import 'package:horus_system/features/company/domain/usecases/download_company_brand_logo_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/get_company_brand_profile_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/remove_company_brand_logo_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/update_company_brand_logo_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/update_company_brand_profile_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/validate_company_brand_logo_usecase.dart';
import 'package:horus_system/features/company/presentation/cubit/company_branding_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/company_branding_state.dart';

void main() {
  test('load, edit and revalidate identity through use cases', () async {
    final repo = _FakeRepository();
    final cubit = _build(repo);
    addTearDown(cubit.close);
    await cubit.load(_context(CompanyRole.owner));
    expect(cubit.state, isA<CompanyBrandingReady>());

    await cubit.saveProfile(
      companyContext: _context(CompanyRole.owner),
      name: 'New Profile',
    );
    final ready = cubit.state as CompanyBrandingReady;
    expect(ready.notice, CompanyBrandingNotice.profileSaved);
    expect(repo.updatedName, 'New Profile');
    expect(repo.companyId, 'tenant-1');
  });

  test('unauthorized role cannot change logo', () async {
    final repo = _FakeRepository();
    final cubit = _build(repo);
    addTearDown(cubit.close);
    await cubit.load(_context(CompanyRole.viewer));
    final result = await cubit.uploadLogo(
      companyContext: _context(CompanyRole.viewer),
      logo: CompanyBrandLogoFile(
        fileName: 'logo.png',
        bytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
      ),
    );
    expect(result.isFailure, isTrue);
    expect(repo.uploads, 0);
  });
}

CompanyBrandingCubit _build(CompanyBrandingRepository repository) =>
    CompanyBrandingCubit(
      getProfile: GetCompanyBrandProfileUseCase(repository),
      updateProfile: UpdateCompanyBrandProfileUseCase(repository),
      updateLogo: UpdateCompanyBrandLogoUseCase(repository),
      removeLogo: RemoveCompanyBrandLogoUseCase(repository),
      downloadLogo: DownloadCompanyBrandLogoUseCase(repository),
      validateLogo: const ValidateCompanyBrandLogoUseCase(),
    );

CurrentCompanyContext _context(CompanyRole role) => CurrentCompanyContext(
  company: const Company(id: 'tenant-1', name: 'Example'),
  role: role,
);

final class _FakeRepository implements CompanyBrandingRepository {
  String? companyId;
  String? updatedName;
  int uploads = 0;
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
    this.companyId = companyId;
    updatedName = name;
    return Success(profile);
  }

  @override
  Future<Result<CompanyBrandProfile>> updateLogo({
    required String companyId,
    required String? expectedLogoPath,
    required CompanyBrandLogoFile logo,
  }) async {
    uploads++;
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
  }) async => Success(Uint8List(0));
}
