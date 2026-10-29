import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/app/routing/app_route_guards.dart';
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
import 'package:horus_system/features/auth/presentation/pages/login_page.dart';
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
import 'package:horus_system/features/company/presentation/pages/company_entry_page.dart';
import 'package:horus_system/features/company/presentation/widgets/company_context_access_view.dart';
import 'package:horus_system/features/company/presentation/widgets/company_session_lifecycle_boundary.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('protected deep link updates its role from a membership hint', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await harness.auth.checkCurrentUser();
    await tester.pumpWidget(harness.widget(_protectedScreen()));
    await tester.pumpAndSettle();

    expect(find.text('owner'), findsOneWidget);
    expect(harness.membership.watchCalls, 1);
    expect(harness.membership.activeSubscriptions, 1);

    harness.companyRepository.contexts = [_context(CompanyRole.viewer)];
    harness.membership.invalidate();
    await tester.pumpAndSettle();

    expect(find.text('viewer'), findsOneWidget);
    expect(find.text('owner'), findsNothing);
    expect(harness.membership.watchCalls, 1);
  });

  testWidgets('token renewal revalidates an already-open protected route', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await harness.auth.checkCurrentUser();
    await tester.pumpWidget(harness.widget(_protectedScreen()));
    await tester.pumpAndSettle();

    final before = harness.companyRepository.loads;
    harness.companyRepository.contexts = [_context(CompanyRole.operations)];
    harness.sessions.notify(AuthSessionChange.tokenRefreshed);
    await tester.pumpAndSettle();

    expect(find.text('operations'), findsOneWidget);
    expect(harness.companyRepository.loads, greaterThan(before));
    expect(harness.membership.activeSubscriptions, 1);
  });

  testWidgets('revocation blocks deep link and reactivation restores it', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await harness.auth.checkCurrentUser();
    await tester.pumpWidget(harness.widget(_protectedScreen()));
    await tester.pumpAndSettle();

    harness.companyRepository.contexts = const [];
    harness.membership.invalidate();
    await tester.pumpAndSettle();

    expect(find.byType(CompanyEntryPage), findsOneWidget);
    expect(find.byKey(const Key('protected-company-content')), findsNothing);

    harness.companyRepository.contexts = [_context(CompanyRole.viewer)];
    harness.membership.invalidate();
    await tester.pumpAndSettle();

    expect(find.text('viewer'), findsOneWidget);
    expect(harness.membership.watchCalls, 1);
  });

  testWidgets('resume and reconnect revalidate a protected route', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await harness.auth.checkCurrentUser();
    await harness.network.startWatching();
    harness.networkRepository.notify(NetworkConnectionStatus.online);
    await tester.pumpWidget(harness.widget(_protectedScreen()));
    await tester.pumpAndSettle();

    final beforeResume = harness.companyRepository.loads;
    harness.companyRepository.contexts = [_context(CompanyRole.admin)];
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('admin'), findsOneWidget);
    expect(harness.companyRepository.loads, greaterThan(beforeResume));

    harness.networkRepository.notify(NetworkConnectionStatus.offline);
    await tester.pump();
    harness.companyRepository.contexts = [_context(CompanyRole.viewer)];
    harness.networkRepository.notify(NetworkConnectionStatus.online);
    await tester.pumpAndSettle();

    expect(find.text('viewer'), findsOneWidget);
    expect(harness.membership.watchCalls, 1);
  });

  testWidgets('sign-out removes membership watcher and protected content', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await harness.auth.checkCurrentUser();
    await tester.pumpWidget(harness.widget(_protectedScreen()));
    await tester.pumpAndSettle();

    harness.sessions.notify(AuthSessionChange.signedOut);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byKey(const Key('protected-company-content')), findsNothing);
    expect(harness.membership.activeSubscriptions, 0);
  });

  testWidgets('verification failure hides old role until successful retry', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await harness.auth.checkCurrentUser();
    await tester.pumpWidget(harness.widget(_protectedScreen()));
    await tester.pumpAndSettle();

    harness.companyRepository.nextLoadResult = const FailureResult(
      NetworkFailure(code: CompanyFailureCodes.contextConnectionUnavailable),
    );
    await harness.company.revalidateSelectedCompany();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('protected-company-content')), findsNothing);
    expect(find.text('Retry'), findsOneWidget);

    harness.companyRepository.contexts = [_context(CompanyRole.viewer)];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('viewer'), findsOneWidget);
    expect(find.text('owner'), findsNothing);
  });

  testWidgets('late verification cannot restore a signed-out deep link', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await harness.auth.checkCurrentUser();
    await tester.pumpWidget(harness.widget(_protectedScreen()));
    await tester.pumpAndSettle();

    final pending = Completer<Result<List<CurrentCompanyContext>>>();
    harness.companyRepository.pendingLoad = pending;
    final validation = harness.company.revalidateSelectedCompany();
    await tester.pump();

    harness.sessions.notify(AuthSessionChange.signedOut);
    await tester.pump();
    pending.complete(Success([_context(CompanyRole.owner)]));
    await validation;
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byKey(const Key('protected-company-content')), findsNothing);
    expect(harness.membership.activeSubscriptions, 0);
  });

  testWidgets('same-role verification blocks taps but keeps draft state', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await harness.auth.checkCurrentUser();
    await harness.company.loadCurrentCompanyContext();
    await tester.pumpWidget(
      harness.widget(
        CompanyContextAccessView(builder: (_) => const _DraftContent()),
        withSessionBoundary: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('draft-text')), 'unsaved');
    final pending = Completer<Result<List<CurrentCompanyContext>>>();
    harness.companyRepository.pendingLoad = pending;
    final validation = harness.company.revalidateSelectedCompany();
    await tester.pump();

    expect(find.byKey(const Key('draft-text')), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('draft-action')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(find.text('Action triggered'), findsNothing);

    pending.complete(Success([_context(CompanyRole.owner)]));
    await validation;
    await tester.pumpAndSettle();

    expect(find.text('unsaved'), findsOneWidget);
    await tester.tap(find.byKey(const Key('draft-action')));
    await tester.pump();
    expect(find.text('Action triggered'), findsOneWidget);
  });

  testWidgets(
    'recoverable connection failure hides company data but restores draft',
    (tester) async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.auth.checkCurrentUser();
      await harness.company.loadCurrentCompanyContext();
      await tester.pumpWidget(
        harness.widget(
          CompanyContextAccessView(builder: (_) => const _DraftContent()),
          withSessionBoundary: false,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('draft-text')), 'retained');
      harness.companyRepository.nextLoadResult = const FailureResult(
        NetworkFailure(code: CompanyFailureCodes.contextConnectionUnavailable),
      );
      await harness.company.revalidateSelectedCompany();
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byKey(const Key('draft-text')), findsNothing);

      await harness.company.revalidateSelectedCompany();
      await tester.pumpAndSettle();

      expect(find.text('retained'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    },
  );

  testWidgets('repeated membership channel errors do not retry while offline', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await harness.auth.checkCurrentUser();
    await harness.company.loadCurrentCompanyContext();
    harness.company.startWatchingMembership('user-a');
    await tester.pumpWidget(
      harness.widget(
        CompanyContextAccessView(builder: (_) => const _DraftContent()),
        withSessionBoundary: false,
      ),
    );

    harness.companyRepository.nextLoadResult = const FailureResult(
      NetworkFailure(code: CompanyFailureCodes.contextConnectionUnavailable),
    );
    await harness.company.revalidateSelectedCompany();
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);

    final loadsDuringFailure = harness.companyRepository.loads;
    harness.membership.fail();
    harness.membership.fail();
    await tester.pumpAndSettle();

    expect(harness.companyRepository.loads, loadsDuringFailure);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('role change discards old role-specific form state', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await harness.auth.checkCurrentUser();
    await harness.company.loadCurrentCompanyContext();
    await tester.pumpWidget(
      harness.widget(
        CompanyContextAccessView(builder: (_) => const _DraftContent()),
        withSessionBoundary: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('draft-text')),
      'private draft',
    );
    harness.companyRepository.contexts = [_context(CompanyRole.viewer)];
    await harness.company.revalidateSelectedCompany();
    await tester.pumpAndSettle();

    expect(find.text('private draft'), findsNothing);
    expect(find.byKey(const Key('draft-text')), findsOneWidget);
  });
}

Widget _protectedScreen() => CompanyRequiredRouteGuard(
  builder: (companyContext) => Scaffold(
    body: Center(
      child: Text(
        companyContext.role.name,
        key: const Key('protected-company-content'),
      ),
    ),
  ),
);

CurrentCompanyContext _context(CompanyRole role) => CurrentCompanyContext(
  company: const Company(id: 'company-a', name: 'Company A'),
  role: role,
);

class _DraftContent extends StatefulWidget {
  const _DraftContent();

  @override
  State<_DraftContent> createState() => _DraftContentState();
}

class _DraftContentState extends State<_DraftContent> {
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TextField(key: Key('draft-text')),
          ElevatedButton(
            key: const Key('draft-action'),
            onPressed: () => setState(() => _triggered = true),
            child: const Text('Action'),
          ),
          if (_triggered) const Text('Action triggered'),
        ],
      ),
    );
  }
}

class _Harness {
  final _FakeCompanyRepository companyRepository = _FakeCompanyRepository();
  final _FakeMembershipRepository membership = _FakeMembershipRepository();
  final _FakeSessionRepository sessions = _FakeSessionRepository();
  final _FakeNetworkRepository networkRepository = _FakeNetworkRepository();

  late final AuthCubit auth = AuthCubit(
    registerUseCase: RegisterUseCase(_FakeAuthRepository()),
    loginUseCase: LoginUseCase(_FakeAuthRepository()),
    logoutUseCase: LogoutUseCase(_FakeAuthRepository()),
    getCurrentUserUseCase: GetCurrentUserUseCase(_FakeAuthRepository()),
    watchSessionChangesUseCase: WatchAuthSessionChangesUseCase(sessions),
  )..startWatchingSession();

  late final CurrentCompanyCubit company = CurrentCompanyCubit(
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
      membership,
    ),
  );

  late final NetworkStatusCubit network = NetworkStatusCubit(
    getNetworkStatusUseCase: GetNetworkStatusUseCase(networkRepository),
    watchNetworkStatusUseCase: WatchNetworkStatusUseCase(networkRepository),
    pollingEnabled: false,
  );

  Widget widget(Widget child, {bool withSessionBoundary = true}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: auth),
        BlocProvider<CurrentCompanyCubit>.value(value: company),
        BlocProvider<NetworkStatusCubit>.value(value: network),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: withSessionBoundary
            ? CompanySessionLifecycleBoundary(child: child)
            : child,
      ),
    );
  }

  Future<void> dispose() async {
    await auth.close();
    await company.close();
    await network.close();
    await sessions.dispose();
    await membership.dispose();
    await networkRepository.dispose();
  }
}

class _FakeCompanyRepository implements CompanyContextRepository {
  List<CurrentCompanyContext> contexts = [_context(CompanyRole.owner)];
  Completer<Result<List<CurrentCompanyContext>>>? pendingLoad;
  Result<List<CurrentCompanyContext>>? nextLoadResult;
  int loads = 0;

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() async {
    loads++;
    final nextResult = nextLoadResult;
    nextLoadResult = null;
    if (nextResult != null) return nextResult;
    final pending = pendingLoad;
    if (pending != null) {
      pendingLoad = null;
      return pending.future;
    }
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

class _FakeMembershipRepository implements CompanyMembershipChangesRepository {
  late final StreamController<Result<CompanyMembershipChange>> controller =
      StreamController<Result<CompanyMembershipChange>>.broadcast(
        onListen: () => activeSubscriptions++,
        onCancel: () => activeSubscriptions--,
      );
  int watchCalls = 0;
  int activeSubscriptions = 0;

  @override
  Stream<Result<CompanyMembershipChange>> watchChanges({
    required String userId,
  }) {
    watchCalls++;
    return controller.stream;
  }

  void invalidate() =>
      controller.add(const Success(CompanyMembershipChange.invalidated));

  void fail() => controller.addError(StateError('connection unavailable'));


  Future<void> dispose() => controller.close();
}

class _FakeSessionRepository implements AuthSessionChangesRepository {
  final controller = StreamController<AuthSessionChange>.broadcast();

  @override
  Stream<AuthSessionChange> watchSessionChanges() => controller.stream;

  void notify(AuthSessionChange change) => controller.add(change);

  Future<void> dispose() => controller.close();
}

class _FakeNetworkRepository implements NetworkStatusRepository {
  final controller =
      StreamController<Result<NetworkConnectionStatus>>.broadcast();

  @override
  Future<Result<NetworkConnectionStatus>> getCurrentStatus() async =>
      const Success(NetworkConnectionStatus.online);

  @override
  Stream<Result<NetworkConnectionStatus>> watchStatus() => controller.stream;

  void notify(NetworkConnectionStatus status) =>
      controller.add(Success(status));

  Future<void> dispose() => controller.close();
}

class _FakeAuthRepository implements AuthRepository {
  static const _user = AuthUser(
    id: 'user-a',
    email: 'member@example.com',
    isEmailConfirmed: true,
  );

  @override
  Future<Result<AuthUser?>> getCurrentUser() async => const Success(_user);

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
  Future<Result<void>> logout() async => const Success(null);
}
