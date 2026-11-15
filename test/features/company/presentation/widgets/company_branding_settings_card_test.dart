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
import 'package:horus_system/features/company/domain/repositories/company_context_repository.dart';
import 'package:horus_system/features/company/domain/usecases/clear_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/load_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/refresh_selected_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/select_current_company_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/download_company_brand_logo_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/get_company_brand_profile_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/remove_company_brand_logo_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/update_company_brand_logo_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/update_company_brand_profile_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/validate_company_brand_logo_usecase.dart';
import 'package:horus_system/features/company/presentation/cubit/company_branding_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/current_company_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/current_company_state.dart';
import 'package:horus_system/features/company/presentation/widgets/company_context_access_view.dart';
import 'package:horus_system/features/company/presentation/widgets/company_branding_settings_card.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'saving branding keeps Settings mounted and preserves unrelated draft',
    (tester) async {
      final contextRepository = _FakeCompanyContextRepository();
      final currentCompanyCubit = CurrentCompanyCubit(
        loadCurrentCompanyContextUseCase: LoadCurrentCompanyContextUseCase(
          contextRepository,
        ),
        selectCurrentCompanyUseCase: SelectCurrentCompanyUseCase(
          contextRepository,
        ),
        refreshSelectedCompanyContextUseCase:
            RefreshSelectedCompanyContextUseCase(contextRepository),
        clearCurrentCompanyContextUseCase: ClearCurrentCompanyContextUseCase(
          contextRepository,
        ),
      );
      final brandingRepository = _FakeBrandingRepository();
      final brandingCubit = CompanyBrandingCubit(
        getProfile: GetCompanyBrandProfileUseCase(brandingRepository),
        updateProfile: UpdateCompanyBrandProfileUseCase(brandingRepository),
        updateLogo: UpdateCompanyBrandLogoUseCase(brandingRepository),
        removeLogo: RemoveCompanyBrandLogoUseCase(brandingRepository),
        downloadLogo: DownloadCompanyBrandLogoUseCase(brandingRepository),
        validateLogo: const ValidateCompanyBrandLogoUseCase(),
      );
      addTearDown(currentCompanyCubit.close);
      addTearDown(brandingCubit.close);
      await currentCompanyCubit.loadCurrentCompanyContext();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<CurrentCompanyCubit>.value(value: currentCompanyCubit),
            BlocProvider<CompanyBrandingCubit>.value(value: brandingCubit),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CompanyContextAccessView(
              builder: (companyContext) => Scaffold(
                body: Column(
                  children: [
                    const TextField(key: Key('unsaved-draft')),
                    Expanded(
                      child: SingleChildScrollView(
                        child: CompanyBrandingSettingsCard(
                          currentCompanyContext: companyContext,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('unsaved-draft')),
        'keep this draft in Settings',
      );

      await tester.ensureVisible(find.text('Save company profile'));
      await tester.tap(find.text('Save company profile'));
      await tester.pumpAndSettle();

      expect(contextRepository.loads, 2);
      expect(currentCompanyCubit.state, isA<CurrentCompanyLoaded>());
      expect(find.text('Company profile and branding'), findsOneWidget);
      expect(find.byKey(const Key('unsaved-draft')), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        'keep this draft in Settings',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('owner sees editable company branding and profile fields', (
    tester,
  ) async {
    await _pumpSettings(tester, role: CompanyRole.owner);

    expect(find.text('Company profile and branding'), findsOneWidget);
    expect(find.text('Save company profile'), findsOneWidget);
    expect(find.text('Select logo'), findsOneWidget);
    expect(find.text('Business address'), findsOneWidget);
    expect(find.text('Registration / tax number (optional)'), findsOneWidget);
  });

  testWidgets('viewer can read identity but not mutate company branding', (
    tester,
  ) async {
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

final class _FakeCompanyContextRepository implements CompanyContextRepository {
  static const currentContext = CurrentCompanyContext(
    company: Company(id: 'company-1', name: 'Transport'),
    role: CompanyRole.owner,
  );

  int loads = 0;

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() async {
    loads += 1;
    return const Success([currentContext]);
  }

  @override
  Future<Result<CurrentCompanyContext>> selectCompany(String companyId) async =>
      const Success(currentContext);

  @override
  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext() async =>
      const Success<CurrentCompanyContext?>(currentContext);

  @override
  Future<Result<void>> clearCurrentCompanyContext() async =>
      const Success<void>(null);
}
