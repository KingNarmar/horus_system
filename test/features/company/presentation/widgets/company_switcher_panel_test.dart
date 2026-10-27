import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_context_repository.dart';
import 'package:horus_system/features/company/domain/usecases/clear_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/get_switchable_company_contexts_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/load_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/refresh_selected_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/select_current_company_usecase.dart';
import 'package:horus_system/features/company/presentation/cubit/company_switcher_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/current_company_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/current_company_state.dart';
import 'package:horus_system/features/company/presentation/widgets/company_switcher_panel.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/core/errors/common_failures.dart';

void main() {
  testWidgets('shows authorized companies and switches to server-verified role', (
    tester,
  ) async {
    final repository = _MembershipRepository();
    final current = _currentCubit(repository);
    final choices = _choicesCubit(repository);
    addTearDown(current.close);
    addTearDown(choices.close);
    await current.loadCurrentCompanyContext();
    await choices.load();
    var completed = 0;

    await tester.pumpWidget(
      _app(
        current: current,
        choices: choices,
        onSwitchSucceeded: () => completed++,
      ),
    );

    expect(find.text('First Company'), findsOneWidget);
    expect(find.text('Second Company'), findsOneWidget);
    expect(find.text('Accountant'), findsOneWidget);
    expect(find.text('Join another company'), findsOneWidget);

    await tester.tap(find.text('Second Company'));
    await tester.pumpAndSettle();

    final context = (current.state as CurrentCompanyLoaded).context;
    expect(context.companyId, 'company-b');
    expect(context.role, CompanyRole.accountant);
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the company picker correctly in Arabic RTL', (
    tester,
  ) async {
    final repository = _MembershipRepository();
    final current = _currentCubit(repository);
    final choices = _choicesCubit(repository);
    addTearDown(current.close);
    addTearDown(choices.close);
    await current.loadCurrentCompanyContext();
    await choices.load();

    await tester.pumpWidget(
      _app(
        current: current,
        choices: choices,
        locale: const Locale('ar'),
      ),
    );

    expect(find.text('شركاتك'), findsOneWidget);
    final join = find.text('الانضمام إلى شركة أخرى');
    expect(join, findsOneWidget);
    expect(Directionality.of(tester.element(join)), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}

Widget _app({
  required CurrentCompanyCubit current,
  required CompanySwitcherCubit choices,
  Locale locale = const Locale('en'),
  VoidCallback? onSwitchSucceeded,
}) => MultiBlocProvider(
  providers: [
    BlocProvider<CurrentCompanyCubit>.value(value: current),
    BlocProvider<CompanySwitcherCubit>.value(value: choices),
  ],
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: CompanySwitcherPanel(
          activeCompanyId: 'company-a',
          onSwitchSucceeded: onSwitchSucceeded,
          onJoin: () {},
        ),
      ),
    ),
  ),
);

CurrentCompanyCubit _currentCubit(CompanyContextRepository repository) =>
    CurrentCompanyCubit(
      loadCurrentCompanyContextUseCase: LoadCurrentCompanyContextUseCase(
        repository,
      ),
      selectCurrentCompanyUseCase: SelectCurrentCompanyUseCase(repository),
      refreshSelectedCompanyContextUseCase:
          RefreshSelectedCompanyContextUseCase(repository),
      clearCurrentCompanyContextUseCase: ClearCurrentCompanyContextUseCase(
        repository,
      ),
    );

CompanySwitcherCubit _choicesCubit(CompanyContextRepository repository) =>
    CompanySwitcherCubit(
      getCompanies: GetSwitchableCompanyContextsUseCase(repository),
    );

final class _MembershipRepository implements CompanyContextRepository {
  final List<CurrentCompanyContext> companies = const [
    CurrentCompanyContext(
      company: Company(id: 'company-a', name: 'First Company'),
      role: CompanyRole.owner,
    ),
    CurrentCompanyContext(
      company: Company(id: 'company-b', name: 'Second Company'),
      role: CompanyRole.accountant,
    ),
  ];

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() async =>
      Success(companies);

  @override
  Future<Result<CurrentCompanyContext>> selectCompany(String companyId) async {
    for (final context in companies) {
      if (context.companyId == companyId) return Success(context);
    }
    return const FailureResult(
      ValidationFailure(code: CompanyFailureCodes.companyNotAvailable),
    );
  }

  @override
  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext() async =>
      Success(companies.first);

  @override
  Future<Result<void>> clearCurrentCompanyContext() async =>
      const Success(null);
}
