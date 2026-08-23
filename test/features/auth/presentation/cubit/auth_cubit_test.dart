import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/domain/entities/auth_user.dart';
import 'package:horus_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:horus_system/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/login_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/logout_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/register_usecase.dart';
import 'package:horus_system/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:horus_system/features/auth/presentation/cubit/auth_state.dart';
import 'package:test/test.dart';

void main() {
  group('AuthCubit', () {
    test('starts in AuthInitial', () async {
      final cubit = _createCubit(_FakeAuthRepository());
      addTearDown(cubit.close);

      expect(cubit.state, isA<AuthInitial>());
    });

    test('checkCurrentUser emits loading then authenticated', () async {
      final repository = _FakeAuthRepository(
        currentUserResult: const Success<AuthUser?>(_confirmedUser),
      );
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final states = await _recordStates(cubit, cubit.checkCurrentUser);

      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthAuthenticated>());
      expect((states[1] as AuthAuthenticated).user, same(_confirmedUser));
      expect(repository.getCurrentUserCalls, 1);
    });

    test('checkCurrentUser emits unauthenticated for null user', () async {
      final repository = _FakeAuthRepository(
        currentUserResult: const Success<AuthUser?>(null),
      );
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final states = await _recordStates(cubit, cubit.checkCurrentUser);

      expect(states.map((state) => state.runtimeType), [
        AuthLoading,
        AuthUnauthenticated,
      ]);
    });

    test('checkCurrentUser emits failure state on failure', () async {
      const failure = UnexpectedFailure(message: 'restore failed');
      final repository = _FakeAuthRepository(
        currentUserResult: const FailureResult<AuthUser?>(failure),
      );
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final states = await _recordStates(cubit, cubit.checkCurrentUser);

      expect(states[0], isA<AuthLoading>());
      expect((states[1] as AuthFailureState).failure, same(failure));
    });

    test('login emits loading then authenticated', () async {
      final repository = _FakeAuthRepository(
        loginResult: const Success<AuthUser>(_confirmedUser),
      );
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final states = await _recordStates(
        cubit,
        () => cubit.login(email: 'user@example.com', password: 'secret'),
      );

      expect(states[0], isA<AuthLoading>());
      expect((states[1] as AuthAuthenticated).user, same(_confirmedUser));
      expect(repository.loginCalls, 1);
    });

    test('login emits failure state when use case fails', () async {
      const failure = UnexpectedFailure(message: 'login failed');
      final repository = _FakeAuthRepository(
        loginResult: const FailureResult<AuthUser>(failure),
      );
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final states = await _recordStates(
        cubit,
        () => cubit.login(email: 'user@example.com', password: 'secret'),
      );

      expect(states[0], isA<AuthLoading>());
      expect((states[1] as AuthFailureState).failure, same(failure));
    });

    test('register authenticates an email-confirmed user', () async {
      final repository = _FakeAuthRepository(
        registerResult: const Success<AuthUser>(_confirmedUser),
      );
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final states = await _recordStates(
        cubit,
        () => cubit.register(
          fullName: 'Mina Adly',
          phone: '0500000000',
          email: 'user@example.com',
          password: 'secret',
        ),
      );

      expect(states[0], isA<AuthLoading>());
      expect((states[1] as AuthAuthenticated).user, same(_confirmedUser));
      expect(repository.registerCalls, 1);
    });

    test('register requires email confirmation for unconfirmed user', () async {
      final repository = _FakeAuthRepository(
        registerResult: const Success<AuthUser>(_unconfirmedUser),
      );
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final states = await _recordStates(
        cubit,
        () => cubit.register(
          fullName: 'Mina Adly',
          phone: '0500000000',
          email: 'fallback@example.com',
          password: 'secret',
        ),
      );

      expect(states[0], isA<AuthLoading>());
      final confirmationState = states[1] as AuthEmailConfirmationRequired;
      expect(confirmationState.email, _unconfirmedUser.email);
    });

    test('register emits failure state when use case fails', () async {
      const failure = UnexpectedFailure(message: 'register failed');
      final repository = _FakeAuthRepository(
        registerResult: const FailureResult<AuthUser>(failure),
      );
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final states = await _recordStates(
        cubit,
        () => cubit.register(
          fullName: 'Mina Adly',
          phone: '0500000000',
          email: 'user@example.com',
          password: 'secret',
        ),
      );

      expect(states[0], isA<AuthLoading>());
      expect((states[1] as AuthFailureState).failure, same(failure));
    });

    test('logout emits loading then unauthenticated on success', () async {
      final repository = _FakeAuthRepository(
        logoutResult: const Success<void>(null),
      );
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final states = await _recordStates(cubit, cubit.logout);

      expect(states.map((state) => state.runtimeType), [
        AuthLoading,
        AuthUnauthenticated,
      ]);
      expect(repository.logoutCalls, 1);
    });

    test('logout emits failure state on failure', () async {
      const failure = UnexpectedFailure(message: 'logout failed');
      final repository = _FakeAuthRepository(
        logoutResult: const FailureResult<void>(failure),
      );
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final states = await _recordStates(cubit, cubit.logout);

      expect(states[0], isA<AuthLoading>());
      expect((states[1] as AuthFailureState).failure, same(failure));
    });
  });
}

const _confirmedUser = AuthUser(
  id: 'user-1',
  email: 'user@example.com',
  phone: '0500000000',
  fullName: 'Mina Adly',
  isEmailConfirmed: true,
);

const _unconfirmedUser = AuthUser(
  id: 'user-2',
  email: 'pending@example.com',
  isEmailConfirmed: false,
);

AuthCubit _createCubit(_FakeAuthRepository repository) {
  return AuthCubit(
    registerUseCase: RegisterUseCase(repository),
    loginUseCase: LoginUseCase(repository),
    logoutUseCase: LogoutUseCase(repository),
    getCurrentUserUseCase: GetCurrentUserUseCase(repository),
  );
}

Future<List<AuthState>> _recordStates(
  AuthCubit cubit,
  Future<void> Function() action,
) async {
  final states = cubit.stream.take(2).toList();
  await action();
  return states;
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    Result<AuthUser>? registerResult,
    Result<AuthUser>? loginResult,
    Result<void>? logoutResult,
    Result<AuthUser?>? currentUserResult,
  }) : registerResult =
           registerResult ?? const Success<AuthUser>(_confirmedUser),
       loginResult = loginResult ?? const Success<AuthUser>(_confirmedUser),
       logoutResult = logoutResult ?? const Success<void>(null),
       currentUserResult =
           currentUserResult ?? const Success<AuthUser?>(_confirmedUser);

  Result<AuthUser> registerResult;
  Result<AuthUser> loginResult;
  Result<void> logoutResult;
  Result<AuthUser?> currentUserResult;

  int registerCalls = 0;
  int loginCalls = 0;
  int logoutCalls = 0;
  int getCurrentUserCalls = 0;

  @override
  Future<Result<AuthUser>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    registerCalls++;
    return registerResult;
  }

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    return loginResult;
  }

  @override
  Future<Result<void>> logout() async {
    logoutCalls++;
    return logoutResult;
  }

  @override
  Future<Result<AuthUser?>> getCurrentUser() async {
    getCurrentUserCalls++;
    return currentUserResult;
  }
}
