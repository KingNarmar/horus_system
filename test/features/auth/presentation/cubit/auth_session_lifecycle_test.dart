import 'dart:async';

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
import 'package:horus_system/features/auth/presentation/cubit/auth_state.dart';
import 'package:test/test.dart';

const _user = AuthUser(
  id: 'user-a',
  email: 'user@example.com',
  isEmailConfirmed: true,
);

void main() {
  test('token renewal preserves identity and invalidates company session revision', () async {
    final changes = _FakeSessionEventsRepository();
    final repository = _FakeAuthRepository();
    final cubit = _createCubit(repository, changes)..startWatchingSession();
    addTearDown(() async {
      await cubit.close();
      await changes.dispose();
    });

    await cubit.checkCurrentUser();
    expect(cubit.state, isA<AuthAuthenticated>());
    changes.add(AuthSessionChange.tokenRefreshed);
    await Future<void>.delayed(Duration.zero);

    final renewed = cubit.state as AuthAuthenticated;
    expect(renewed.user.id, _user.id);
    expect(renewed.sessionRevision, 1);
  });

  test('external sign-out immediately invalidates authenticated UI', () async {
    final changes = _FakeSessionEventsRepository();
    final cubit = _createCubit(_FakeAuthRepository(), changes)
      ..startWatchingSession();
    addTearDown(() async {
      await cubit.close();
      await changes.dispose();
    });

    await cubit.checkCurrentUser();
    changes.add(AuthSessionChange.signedOut);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<AuthUnauthenticated>());
  });

  test('late login response cannot restore a signed-out user', () async {
    final changes = _FakeSessionEventsRepository();
    final repository = _FakeAuthRepository();
    final pendingLogin = Completer<Result<AuthUser>>();
    repository.pendingLogin = pendingLogin;
    final cubit = _createCubit(repository, changes)..startWatchingSession();
    addTearDown(() async {
      await cubit.close();
      await changes.dispose();
    });

    final login = cubit.login(email: 'user@example.com', password: 'secret');
    changes.add(AuthSessionChange.signedOut);
    await Future<void>.delayed(Duration.zero);
    pendingLogin.complete(const Success(_user));
    await login;

    expect(cubit.state, isA<AuthUnauthenticated>());
  });

  test('user deletion ends the active company session', () async {
    final changes = _FakeSessionEventsRepository();
    final cubit = _createCubit(_FakeAuthRepository(), changes)
      ..startWatchingSession();
    addTearDown(() async {
      await cubit.close();
      await changes.dispose();
    });
    await cubit.checkCurrentUser();

    changes.add(AuthSessionChange.userDeleted);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<AuthUnauthenticated>());
  });
}

AuthCubit _createCubit(
  _FakeAuthRepository repository,
  _FakeSessionEventsRepository changes,
) => AuthCubit(
  registerUseCase: RegisterUseCase(repository),
  loginUseCase: LoginUseCase(repository),
  logoutUseCase: LogoutUseCase(repository),
  getCurrentUserUseCase: GetCurrentUserUseCase(repository),
  watchSessionChangesUseCase: WatchAuthSessionChangesUseCase(changes),
);

final class _FakeSessionEventsRepository implements AuthSessionChangesRepository {
  final _controller = StreamController<AuthSessionChange>.broadcast();

  @override
  Stream<AuthSessionChange> watchSessionChanges() => _controller.stream;

  void add(AuthSessionChange change) => _controller.add(change);

  Future<void> dispose() => _controller.close();
}

final class _FakeAuthRepository implements AuthRepository {
  Completer<Result<AuthUser>>? pendingLogin;

  @override
  Future<Result<AuthUser?>> getCurrentUser() async => const Success(_user);

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async => pendingLogin?.future ?? const Success(_user);

  @override
  Future<Result<void>> logout() async => const Success(null);

  @override
  Future<Result<AuthUser>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async => const Success(_user);
}
