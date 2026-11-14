import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/network/domain/entities/network_connection_status.dart';
import 'package:horus_system/core/network/domain/repositories/network_status_repository.dart';
import 'package:horus_system/core/network/domain/usecases/get_network_status_usecase.dart';
import 'package:horus_system/core/network/domain/usecases/watch_network_status_usecase.dart';
import 'package:horus_system/core/network/presentation/cubit/network_status_cubit.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/domain/entities/auth_session_change.dart';
import 'package:horus_system/features/auth/domain/entities/auth_user.dart';
import 'package:horus_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:horus_system/features/auth/domain/repositories/auth_session_changes_repository.dart';
import 'package:horus_system/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/login_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/logout_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/register_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/watch_auth_session_changes_usecase.dart';
import 'package:horus_system/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_membership_change.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_context_repository.dart';
import 'package:horus_system/features/company/domain/repositories/company_membership_changes_repository.dart';
import 'package:horus_system/features/company/domain/usecases/clear_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/load_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/refresh_selected_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/select_current_company_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/watch_company_membership_changes_usecase.dart';
import 'package:horus_system/features/company/presentation/cubit/current_company_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/current_company_state.dart';
import 'package:horus_system/features/company/presentation/widgets/company_context_access_view.dart';
import 'package:horus_system/features/company/presentation/widgets/company_session_lifecycle_boundary.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('desktop focus-only resumes keep the shell and avoid reads', (
    tester,
  ) async {
    final fixture = _SessionFixture();
    addTearDown(fixture.close);
    await fixture.mount(tester, showCompanyView: true);

    await tester.enterText(find.byKey(const Key('draft')), 'unsaved draft');

    for (var i = 0; i < 3; i++) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    }

    expect(fixture.companyRepository.loads, 1);
    expect(fixture.companyCubit.state, isA<CurrentCompanyLoaded>());
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'unsaved draft',
    );
  });

  testWidgets('Windows hide followed by resume performs one verification', (
    tester,
  ) async {
    final fixture = _SessionFixture();
    addTearDown(fixture.close);
    await fixture.mount(tester);

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();

    expect(fixture.companyRepository.loads, 2);
    expect(fixture.companyCubit.state, isA<CurrentCompanyLoaded>());

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(fixture.companyRepository.loads, 2);
  });

  testWidgets('Android background/foreground sequence verifies once', (
    tester,
  ) async {
    final fixture = _SessionFixture();
    addTearDown(fixture.close);
    await fixture.mount(tester);

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();

    expect(fixture.companyRepository.loads, 2);
    expect(fixture.companyCubit.state, isA<CurrentCompanyLoaded>());
  });

  testWidgets('membership signal still applies a role downgrade', (
    tester,
  ) async {
    final fixture = _SessionFixture();
    addTearDown(fixture.close);
    await fixture.mount(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    fixture.companyRepository.contexts = [_companyContext(CompanyRole.viewer)];
    fixture.membershipRepository.notify();
    await tester.pumpAndSettle();

    expect(fixture.companyRepository.loads, 2);
    expect(
      (fixture.companyCubit.state as CurrentCompanyLoaded).context.role,
      CompanyRole.viewer,
    );
  });

  testWidgets('membership revocation while unfocused clears the company', (
    tester,
  ) async {
    final fixture = _SessionFixture();
    addTearDown(fixture.close);
    await fixture.mount(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    fixture.companyRepository.contexts = const [];
    fixture.membershipRepository.notify();
    await tester.pumpAndSettle();

    expect(fixture.companyRepository.loads, 2);
    expect(fixture.companyCubit.state, isA<CurrentCompanyEmpty>());
  });

  testWidgets('token refresh still verifies current company membership', (
    tester,
  ) async {
    final fixture = _SessionFixture();
    addTearDown(fixture.close);
    await fixture.mount(tester);

    fixture.companyRepository.contexts = [
      _companyContext(CompanyRole.operations),
    ];
    fixture.authSessionRepository.notify(AuthSessionChange.tokenRefreshed);
    await tester.pumpAndSettle();

    expect(fixture.companyRepository.loads, 2);
    expect(
      (fixture.companyCubit.state as CurrentCompanyLoaded).context.role,
      CompanyRole.operations,
    );
  });

  testWidgets('network recovery still performs one membership recheck', (
    tester,
  ) async {
    final fixture = _SessionFixture();
    addTearDown(fixture.close);
    await fixture.mount(tester);
    await fixture.networkCubit.startWatching();

    fixture.networkRepository.notify(NetworkConnectionStatus.online);
    await tester.pump();
    expect(fixture.companyRepository.loads, 1);

    fixture.networkRepository.notify(NetworkConnectionStatus.offline);
    await tester.pump();
    fixture.networkRepository.notify(NetworkConnectionStatus.online);
    await tester.pumpAndSettle();

    expect(fixture.companyRepository.loads, 2);
    expect(fixture.companyCubit.state, isA<CurrentCompanyLoaded>());
  });
}

CurrentCompanyContext _companyContext(CompanyRole role) =>
    CurrentCompanyContext(
      company: const Company(id: 'company-a', name: 'Company A'),
      role: role,
    );

final class _SessionFixture {
  final companyRepository = _FakeCompanyContextRepository();
  final membershipRepository = _FakeMembershipRepository();
  final authRepository = _FakeAuthRepository();
  final authSessionRepository = _FakeAuthSessionRepository();
  final networkRepository = _FakeNetworkRepository();

  late final companyCubit = CurrentCompanyCubit(
    loadCurrentCompanyContextUseCase: LoadCurrentCompanyContextUseCase(
      companyRepository,
    ),
    selectCurrentCompanyUseCase: SelectCurrentCompanyUseCase(companyRepository),
    refreshSelectedCompanyContextUseCase: RefreshSelectedCompanyContextUseCase(
      companyRepository,
    ),
    clearCurrentCompanyContextUseCase: ClearCurrentCompanyContextUseCase(
      companyRepository,
    ),
    watchMembershipChangesUseCase: WatchCompanyMembershipChangesUseCase(
      membershipRepository,
    ),
  );

  late final authCubit = AuthCubit(
    registerUseCase: RegisterUseCase(authRepository),
    loginUseCase: LoginUseCase(authRepository),
    logoutUseCase: LogoutUseCase(authRepository),
    getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
    watchSessionChangesUseCase: WatchAuthSessionChangesUseCase(
      authSessionRepository,
    ),
  );

  late final networkCubit = NetworkStatusCubit(
    getNetworkStatusUseCase: GetNetworkStatusUseCase(networkRepository),
    watchNetworkStatusUseCase: WatchNetworkStatusUseCase(networkRepository),
    pollingEnabled: false,
  );

  Future<void> mount(
    WidgetTester tester, {
    bool showCompanyView = false,
  }) async {
    await authCubit.login(email: 'user@example.test', password: 'password');
    authCubit.startWatchingSession();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<CurrentCompanyCubit>.value(value: companyCubit),
          BlocProvider<NetworkStatusCubit>.value(value: networkCubit),
        ],
        child: CompanySessionLifecycleBoundary(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: showCompanyView
                ? CompanyContextAccessView(
                    builder: (_) =>
                        const Scaffold(body: TextField(key: Key('draft'))),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(companyCubit.state, isA<CurrentCompanyLoaded>());
    expect(companyRepository.loads, 1);
  }

  Future<void> close() async {
    await companyCubit.close();
    await authCubit.close();
    await networkCubit.close();
    await membershipRepository.close();
    await authSessionRepository.close();
    await networkRepository.close();
  }
}

final class _FakeCompanyContextRepository implements CompanyContextRepository {
  List<CurrentCompanyContext> contexts = [_companyContext(CompanyRole.owner)];
  int loads = 0;

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() async {
    loads += 1;
    return Success(contexts);
  }

  @override
  Future<Result<CurrentCompanyContext>> selectCompany(String companyId) async {
    for (final context in contexts) {
      if (context.companyId == companyId) return Success(context);
    }
    return const FailureResult(
      ValidationFailure(code: CompanyFailureCodes.companyNotAvailable),
    );
  }

  @override
  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext() async =>
      Success(contexts.isEmpty ? null : contexts.first);

  @override
  Future<Result<void>> clearCurrentCompanyContext() async =>
      const Success<void>(null);
}

final class _FakeMembershipRepository
    implements CompanyMembershipChangesRepository {
  final _changes = StreamController<Result<CompanyMembershipChange>>.broadcast(
    sync: true,
  );

  void notify() {
    _changes.add(const Success(CompanyMembershipChange.invalidated));
  }

  @override
  Stream<Result<CompanyMembershipChange>> watchChanges({
    required String userId,
  }) => _changes.stream;

  Future<void> close() => _changes.close();
}

final class _FakeAuthSessionRepository implements AuthSessionChangesRepository {
  final _changes = StreamController<AuthSessionChange>.broadcast(sync: true);

  void notify(AuthSessionChange change) => _changes.add(change);

  @override
  Stream<AuthSessionChange> watchSessionChanges() => _changes.stream;

  Future<void> close() => _changes.close();
}

final class _FakeNetworkRepository implements NetworkStatusRepository {
  final _changes = StreamController<Result<NetworkConnectionStatus>>.broadcast(
    sync: true,
  );

  void notify(NetworkConnectionStatus status) => _changes.add(Success(status));

  @override
  Future<Result<NetworkConnectionStatus>> getCurrentStatus() async =>
      const Success(NetworkConnectionStatus.online);

  @override
  Stream<Result<NetworkConnectionStatus>> watchStatus() => _changes.stream;

  Future<void> close() => _changes.close();
}

final class _FakeAuthRepository implements AuthRepository {
  static const _user = AuthUser(id: 'user-a');

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async => const Success(_user);

  @override
  Future<Result<AuthUser>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async => const Success(_user);

  @override
  Future<Result<AuthUser?>> getCurrentUser() async => const Success(_user);

  @override
  Future<Result<void>> logout() async => const Success<void>(null);
}
