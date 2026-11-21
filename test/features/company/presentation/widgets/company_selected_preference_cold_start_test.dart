import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/core/network/domain/entities/network_connection_status.dart';
import 'package:horus_system/core/network/domain/repositories/network_status_repository.dart';
import 'package:horus_system/core/network/domain/usecases/get_network_status_usecase.dart';
import 'package:horus_system/core/network/domain/usecases/watch_network_status_usecase.dart';
import 'package:horus_system/core/network/presentation/cubit/network_status_cubit.dart';
import 'package:horus_system/features/auth/domain/entities/auth_user.dart';
import 'package:horus_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:horus_system/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/login_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/logout_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/register_usecase.dart';
import 'package:horus_system/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/repositories/company_context_repository.dart';
import 'package:horus_system/features/company/domain/repositories/selected_company_preference_repository.dart';
import 'package:horus_system/features/company/domain/usecases/clear_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/load_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/refresh_selected_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/remember_selected_company_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/select_current_company_usecase.dart';
import 'package:horus_system/features/company/presentation/cubit/current_company_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/current_company_state.dart';
import 'package:horus_system/features/company/presentation/widgets/company_session_lifecycle_boundary.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'true widget remount restores user preference without focus reload',
    (tester) async {
      final fixture = _Fixture();
      addTearDown(fixture.dispose);
      await fixture.auth.login(email: 'user-a', password: 'password');

      final first = fixture.newCompanyCubit();
      await tester.pumpWidget(fixture.app(first));
      await tester.pumpAndSettle();
      expect(find.text('company-a'), findsOneWidget);
      expect(fixture.server.loads, 1);

      final result = await first.switchActiveCompany('company-b');
      expect(result.failureOrNull, isNull);
      await tester.pumpAndSettle();
      expect(find.text('company-b'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await first.close();
      final restarted = fixture.newCompanyCubit();
      addTearDown(restarted.close);
      await tester.pumpWidget(
        fixture.app(restarted, locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();
      expect(find.text('company-b'), findsOneWidget);
      expect(fixture.server.loads, 3);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(fixture.server.loads, 3);
      expect(find.text('company-b'), findsOneWidget);
    },
  );

  testWidgets('account switch never displays previous account company', (
    tester,
  ) async {
    final fixture = _Fixture();
    addTearDown(fixture.dispose);
    await fixture.auth.login(email: 'user-a', password: 'password');
    final cubit = fixture.newCompanyCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(fixture.app(cubit));
    await tester.pumpAndSettle();

    await cubit.switchActiveCompany('company-b');
    await tester.pumpAndSettle();
    expect(find.text('company-b'), findsOneWidget);

    await fixture.auth.logout();
    await tester.pumpAndSettle();
    expect(find.text('company-b'), findsNothing);

    await fixture.auth.login(email: 'user-b', password: 'password');
    await tester.pumpAndSettle();
    expect(find.text('company-a'), findsOneWidget);
    expect(fixture.preferences.values['user-b'], isNull);
  });

  testWidgets('revoked preferred company is not shown after cold start', (
    tester,
  ) async {
    final fixture = _Fixture();
    addTearDown(fixture.dispose);
    fixture.preferences.values['user-a'] = 'company-b';
    fixture.server.contexts = [_companyA];
    await fixture.auth.login(email: 'user-a', password: 'password');
    final cubit = fixture.newCompanyCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(fixture.app(cubit));
    await tester.pumpAndSettle();
    expect(find.text('company-b'), findsNothing);
    expect(find.text('company-a'), findsOneWidget);
  });
}

const _companyA = CurrentCompanyContext(
  company: Company(id: 'company-a', name: 'Company A'),
  role: CompanyRole.owner,
);
const _companyB = CurrentCompanyContext(
  company: Company(id: 'company-b', name: 'Company B'),
  role: CompanyRole.admin,
);

final class _Fixture {
  final server = _Server();
  final preferences = _Preferences();
  final authRepository = _AuthRepository();
  final networkRepository = _NetworkRepository();

  late final auth = AuthCubit(
    registerUseCase: RegisterUseCase(authRepository),
    loginUseCase: LoginUseCase(authRepository),
    logoutUseCase: LogoutUseCase(authRepository),
    getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
  );
  late final network = NetworkStatusCubit(
    getNetworkStatusUseCase: GetNetworkStatusUseCase(networkRepository),
    watchNetworkStatusUseCase: WatchNetworkStatusUseCase(networkRepository),
    pollingEnabled: false,
  );

  CurrentCompanyCubit newCompanyCubit() => CurrentCompanyCubit(
    loadCurrentCompanyContextUseCase: LoadCurrentCompanyContextUseCase(
      server,
      preferences: preferences,
    ),
    rememberSelectedCompanyUseCase: RememberSelectedCompanyUseCase(preferences),
    selectCurrentCompanyUseCase: SelectCurrentCompanyUseCase(server),
    refreshSelectedCompanyContextUseCase: RefreshSelectedCompanyContextUseCase(
      server,
    ),
    clearCurrentCompanyContextUseCase: ClearCurrentCompanyContextUseCase(
      server,
    ),
  );

  Widget app(CurrentCompanyCubit company, {Locale? locale}) =>
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<CurrentCompanyCubit>.value(value: company),
          BlocProvider<NetworkStatusCubit>.value(value: network),
        ],
        child: CompanySessionLifecycleBoundary(
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: BlocBuilder<CurrentCompanyCubit, CurrentCompanyState>(
                builder: (_, state) => Center(
                  child: switch (state) {
                    CurrentCompanyLoaded(:final context) => Text(
                      context.companyId,
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> dispose() async {
    await auth.close();
    await network.close();
    await networkRepository.dispose();
  }
}

final class _Server implements CompanyContextRepository {
  List<CurrentCompanyContext> contexts = [_companyA, _companyB];
  int loads = 0;

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() async {
    loads++;
    return Success(contexts);
  }

  @override
  Future<Result<CurrentCompanyContext>> selectCompany(String companyId) async {
    for (final c in contexts) {
      if (c.companyId == companyId) return Success(c);
    }
    throw StateError('Invalid test selection');
  }

  @override
  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext() async =>
      const Success(null);

  @override
  Future<Result<void>> clearCurrentCompanyContext() async =>
      const Success<void>(null);
}

final class _Preferences implements SelectedCompanyPreferenceRepository {
  final Map<String, String> values = {};

  @override
  Future<Result<String?>> read(String userId) async => Success(values[userId]);

  @override
  Future<Result<void>> save({
    required String userId,
    required String companyId,
  }) async {
    values[userId] = companyId;
    return const Success<void>(null);
  }
}

final class _AuthRepository implements AuthRepository {
  AuthUser? user;

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    user = AuthUser(id: email);
    return Success(user!);
  }

  @override
  Future<Result<AuthUser>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async => login(email: email, password: password);

  @override
  Future<Result<AuthUser?>> getCurrentUser() async => Success(user);

  @override
  Future<Result<void>> logout() async {
    user = null;
    return const Success<void>(null);
  }
}

final class _NetworkRepository implements NetworkStatusRepository {
  final _controller =
      StreamController<Result<NetworkConnectionStatus>>.broadcast();

  @override
  Future<Result<NetworkConnectionStatus>> getCurrentStatus() async =>
      const Success(NetworkConnectionStatus.online);

  @override
  Stream<Result<NetworkConnectionStatus>> watchStatus() => _controller.stream;

  Future<void> dispose() => _controller.close();
}
