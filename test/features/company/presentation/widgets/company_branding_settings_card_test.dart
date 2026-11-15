import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:horus_system/features/company/presentation/widgets/company_branding_settings_card.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('owner sees editable company branding and profile fields',
      (tester) async {
    await _pumpSettings(tester, role: CompanyRole.owner);

    expect(find.text('Company profile and branding'), findsOneWidget);
    expect(find.text('Save company profile'), findsOneWidget);
    expect(find.text('Select logo'), findsOneWidget);
    expect(find.text('Business address'), findsOneWidget);
    expect(find.text('Registration / tax number (optional)'), findsOneWidget);
  });

  testWidgets('viewer can read identity but not mutate company branding',
      (tester) async {
    await _pumpSettings(tester, role: CompanyRole.viewer);

    expect(find.text('Company profile and branding'), findsOneWidget);
    expect(find.text('Save company profile'), findsNothing);
    expect(find.text('Select logo'), findsNothing);
    expect(find.text('Remove logo'), findsNothing);
    expect(find.text('Business address'), findsOneWidget);
  });

  testWidgets('Arabic owner editor uses localized labels', (tester) async {
    await _pumpSettings(
      tester,
      role: CompanyRole.owner,
      locale: const Locale('ar'),
    );

    expect(find.text('بيانات الشركة والهوية البصرية'), findsOneWidget);
    expect(find.text('حفظ بيانات الشركة'), findsOneWidget);
    expect(find.text('عنوان الشركة'), findsOneWidget);
  });
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  required CompanyRole role,
  Locale locale = const Locale('en'),
}) async {
  final repository = _FakeBrandingRepository();
  final cubit = CompanyBrandingCubit(
    getProfile: GetCompanyBrandProfileUseCase(repository),
    updateProfile: UpdateCompanyBrandProfileUseCase(repository),
    updateLogo: UpdateCompanyBrandLogoUseCase(repository),
    removeLogo: RemoveCompanyBrandLogoUseCase(repository),
    downloadLogo: DownloadCompanyBrandLogoUseCase(repository),
    validateLogo: const ValidateCompanyBrandLogoUseCase(),
  );
  addTearDown(cubit.close);
  await tester.pumpWidget(
    BlocProvider<CompanyBrandingCubit>.value(
      value: cubit,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CompanyBrandingSettingsCard(
              currentCompanyContext: CurrentCompanyContext(
                company: const Company(id: 'company-1', name: 'Transport'),
                role: role,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

final class _FakeBrandingRepository implements CompanyBrandingRepository {
  final CompanyBrandProfile profile = CompanyBrandProfile(
    companyId: 'company-1',
    name: 'Transport',
    businessType: 'Heavy Transport',
    city: 'Dubai',
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
  }) async => Success(profile);

  @override
  Future<Result<CompanyBrandProfile>> updateLogo({
    required String companyId,
    required String? expectedLogoPath,
    required CompanyBrandLogoFile logo,
  }) async => Success(profile);

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
