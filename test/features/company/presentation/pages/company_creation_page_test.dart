import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/app/routing/app_routes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/repositories/company_context_repository.dart';
import 'package:horus_system/features/company/domain/repositories/company_repository.dart';
import 'package:horus_system/features/company/domain/repositories/company_timezone_repository.dart';
import 'package:horus_system/features/company/domain/usecases/clear_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/create_company_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/get_company_timezone_options_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/get_my_companies_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/load_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/refresh_selected_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/select_current_company_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/update_company_business_timezone_usecase.dart';
import 'package:horus_system/features/company/domain/value_objects/company_timezone.dart';
import 'package:horus_system/features/company/presentation/cubit/company_onboarding_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/company_timezone_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/current_company_cubit.dart';
import 'package:horus_system/features/company/presentation/pages/company_creation_page.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('opens app shell only after authoritative company context matches', (
    tester,
  ) async {
    final harness = await _pumpCreationPage(tester);

    await harness.onboardingCubit.createCompany(
      name: _company.name,
      businessTimezone: _company.businessTimezone!,
    );
    await tester.pumpAndSettle();

    expect(find.text('app-shell-route'), findsOneWidget);
    expect(harness.companyRepository.createCompanyCallCount, 1);
    expect(harness.contextRepository.selectCompanyCallCount, 1);
    expect(harness.contextRepository.lastSelectedCompanyId, _company.id);
  });

  testWidgets(
    'mismatched context stays outside workspace and retry does not recreate company',
    (tester) async {
      final harness = await _pumpCreationPage(
        tester,
        selectedContexts: const [_otherContext, _targetContext],
      );

      await harness.onboardingCubit.createCompany(
        name: _company.name,
        businessTimezone: _company.businessTimezone!,
      );
      await tester.pumpAndSettle();

      expect(find.text('app-shell-route'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      expect(harness.companyRepository.createCompanyCallCount, 1);
      expect(harness.contextRepository.selectCompanyCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('app-shell-route'), findsOneWidget);
      expect(harness.companyRepository.createCompanyCallCount, 1);
      expect(harness.contextRepository.selectCompanyCallCount, 2);
      expect(harness.contextRepository.lastSelectedCompanyId, _company.id);
    },
  );
}

Future<_CreationPageHarness> _pumpCreationPage(
  WidgetTester tester, {
  List<CurrentCompanyContext> selectedContexts = const [_targetContext],
}) async {
  final companyRepository = _FakeCompanyRepository();
  final contextRepository = _FakeCompanyContextRepository(
    selectedContexts: selectedContexts,
  );
  final timezoneRepository = _FakeCompanyTimezoneRepository();

  final onboardingCubit = CompanyOnboardingCubit(
    createCompanyUseCase: CreateCompanyUseCase(companyRepository),
    getMyCompaniesUseCase: GetMyCompaniesUseCase(companyRepository),
  );
  final currentCompanyCubit = CurrentCompanyCubit(
    loadCurrentCompanyContextUseCase: LoadCurrentCompanyContextUseCase(
      contextRepository,
    ),
    selectCurrentCompanyUseCase: SelectCurrentCompanyUseCase(contextRepository),
    refreshSelectedCompanyContextUseCase:
        RefreshSelectedCompanyContextUseCase(contextRepository),
    clearCurrentCompanyContextUseCase: ClearCurrentCompanyContextUseCase(
      contextRepository,
    ),
  );
  final timezoneCubit = CompanyTimezoneCubit(
    getOptionsUseCase: GetCompanyTimezoneOptionsUseCase(timezoneRepository),
    updateTimezoneUseCase: UpdateCompanyBusinessTimezoneUseCase(
      timezoneRepository,
    ),
  );

  addTearDown(onboardingCubit.close);
  addTearDown(currentCompanyCubit.close);
  addTearDown(timezoneCubit.close);

  await timezoneCubit.loadOptions();

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<CompanyOnboardingCubit>.value(value: onboardingCubit),
        BlocProvider<CurrentCompanyCubit>.value(value: currentCompanyCubit),
        BlocProvider<CompanyTimezoneCubit>.value(value: timezoneCubit),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          AppRoutes.appShell: (_) =>
              const Scaffold(body: Text('app-shell-route')),
        },
        home: const CompanyCreationPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();

  return _CreationPageHarness(
    onboardingCubit: onboardingCubit,
    companyRepository: companyRepository,
    contextRepository: contextRepository,
  );
}

const _company = Company(
  id: 'company-1',
  name: 'Horus Transport',
  businessTimezone: 'Asia/Dubai',
);
const _otherCompany = Company(
  id: 'company-2',
  name: 'Other Company',
  businessTimezone: 'Asia/Dubai',
);
const _targetContext = CurrentCompanyContext(
  company: _company,
  role: CompanyRole.owner,
);
const _otherContext = CurrentCompanyContext(
  company: _otherCompany,
  role: CompanyRole.owner,
);

final class _CreationPageHarness {
  final CompanyOnboardingCubit onboardingCubit;
  final _FakeCompanyRepository companyRepository;
  final _FakeCompanyContextRepository contextRepository;

  const _CreationPageHarness({
    required this.onboardingCubit,
    required this.companyRepository,
    required this.contextRepository,
  });
}

final class _FakeCompanyRepository implements CompanyRepository {
  int createCompanyCallCount = 0;

  @override
  Future<Result<Company>> createCompany({
    required String name,
    required CompanyTimezone businessTimezone,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
  }) async {
    createCompanyCallCount += 1;
    return const Success(_company);
  }

  @override
  Future<Result<List<Company>>> getMyCompanies() async {
    return const Success(<Company>[]);
  }
}

final class _FakeCompanyContextRepository implements CompanyContextRepository {
  final List<CurrentCompanyContext> selectedContexts;
  int selectCompanyCallCount = 0;
  String? lastSelectedCompanyId;

  _FakeCompanyContextRepository({required this.selectedContexts});

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() async {
    return const Success(<CurrentCompanyContext>[_targetContext]);
  }

  @override
  Future<Result<CurrentCompanyContext>> selectCompany(String companyId) async {
    lastSelectedCompanyId = companyId;
    final index = selectCompanyCallCount < selectedContexts.length
        ? selectCompanyCallCount
        : selectedContexts.length - 1;
    selectCompanyCallCount += 1;
    return Success(selectedContexts[index]);
  }

  @override
  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext() async {
    return const Success<CurrentCompanyContext?>(null);
  }

  @override
  Future<Result<void>> clearCurrentCompanyContext() async {
    return const Success<void>(null);
  }
}

final class _FakeCompanyTimezoneRepository
    implements CompanyTimezoneRepository {
  @override
  Future<Result<List<CompanyTimezone>>> getTimezoneOptions() async {
    return Success(<CompanyTimezone>[
      CompanyTimezone.tryParse(_company.businessTimezone!)!,
    ]);
  }

  @override
  Future<Result<Company>> updateBusinessTimezone({
    required String companyId,
    required CompanyTimezone businessTimezone,
  }) async {
    return const Success(_company);
  }
}
