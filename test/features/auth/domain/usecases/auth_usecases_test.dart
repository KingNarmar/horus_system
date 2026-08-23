import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/usecases/usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/domain/entities/auth_user.dart';
import 'package:horus_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:horus_system/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/login_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/logout_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/register_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('LoginUseCase', () {
    test('rejects empty or whitespace email with stable failure code', () async {
      final repository = _FakeAuthRepository();
      final useCase = LoginUseCase(repository);

      final result = await useCase(
        const LoginParams(email: '   ', password: 'secret'),
      );

      expect(result.failureOrNull?.code, FailureCodes.authEmailRequired);
      expect(repository.loginCalls, 0);
    });

    test('rejects empty password with stable failure code', () async {
      final repository = _FakeAuthRepository();
      final useCase = LoginUseCase(repository);

      final result = await useCase(
        const LoginParams(email: 'user@example.com', password: ''),
      );

      expect(result.failureOrNull?.code, FailureCodes.authPasswordRequired);
      expect(repository.loginCalls, 0);
    });

    test('trims email, delegates once, and preserves repository result', () async {
      final expected = Success<AuthUser>(_user);
      final repository = _FakeAuthRepository(loginResult: expected);
      final useCase = LoginUseCase(repository);

      final result = await useCase(
        const LoginParams(email: '  user@example.com  ', password: 'secret'),
      );

      expect(result, same(expected));
      expect(repository.loginCalls, 1);
      expect(repository.lastLoginEmail, 'user@example.com');
      expect(repository.lastLoginPassword, 'secret');
    });
  });

  group('RegisterUseCase', () {
    test('rejects empty full name with stable failure code', () async {
      final repository = _FakeAuthRepository();
      final useCase = RegisterUseCase(repository);

      final result = await useCase(
        const RegisterParams(
          fullName: '  ',
          phone: '0500000000',
          email: 'user@example.com',
          password: 'secret',
        ),
      );

      expect(result.failureOrNull?.code, FailureCodes.authFullNameRequired);
      expect(repository.registerCalls, 0);
    });

    test('rejects empty phone with stable failure code', () async {
      final repository = _FakeAuthRepository();
      final useCase = RegisterUseCase(repository);

      final result = await useCase(
        const RegisterParams(
          fullName: 'Mina',
          phone: '   ',
          email: 'user@example.com',
          password: 'secret',
        ),
      );

      expect(result.failureOrNull?.code, FailureCodes.authPhoneRequired);
      expect(repository.registerCalls, 0);
    });

    test('rejects empty email with stable failure code', () async {
      final repository = _FakeAuthRepository();
      final useCase = RegisterUseCase(repository);

      final result = await useCase(
        const RegisterParams(
          fullName: 'Mina',
          phone: '0500000000',
          email: '   ',
          password: 'secret',
        ),
      );

      expect(result.failureOrNull?.code, FailureCodes.authEmailRequired);
      expect(repository.registerCalls, 0);
    });

    test('rejects password shorter than existing minimum', () async {
      final repository = _FakeAuthRepository();
      final useCase = RegisterUseCase(repository);

      final result = await useCase(
        const RegisterParams(
          fullName: 'Mina',
          phone: '0500000000',
          email: 'user@example.com',
          password: '12345',
        ),
      );

      expect(result.failureOrNull?.code, FailureCodes.authPasswordTooShort);
      expect(repository.registerCalls, 0);
    });

    test('trims text fields, delegates once, and preserves result', () async {
      final expected = Success<AuthUser>(_user);
      final repository = _FakeAuthRepository(registerResult: expected);
      final useCase = RegisterUseCase(repository);

      final result = await useCase(
        const RegisterParams(
          fullName: '  Mina Adly  ',
          phone: '  0500000000  ',
          email: '  user@example.com  ',
          password: 'secret',
        ),
      );

      expect(result, same(expected));
      expect(repository.registerCalls, 1);
      expect(repository.lastRegisterFullName, 'Mina Adly');
      expect(repository.lastRegisterPhone, '0500000000');
      expect(repository.lastRegisterEmail, 'user@example.com');
      expect(repository.lastRegisterPassword, 'secret');
    });
  });

  group('Auth delegation use cases', () {
    test('LogoutUseCase preserves repository success result', () async {
      const expected = Success<void>(null);
      final repository = _FakeAuthRepository(logoutResult: expected);

      final result = await LogoutUseCase(repository)(const NoParams());

      expect(result, same(expected));
      expect(repository.logoutCalls, 1);
    });

    test('LogoutUseCase preserves repository failure result', () async {
      const failure = UnexpectedFailure(message: 'logout failed');
      const expected = FailureResult<void>(failure);
      final repository = _FakeAuthRepository(logoutResult: expected);

      final result = await LogoutUseCase(repository)(const NoParams());

      expect(result, same(expected));
      expect(repository.logoutCalls, 1);
    });

    test('GetCurrentUserUseCase preserves repository result', () async {
      final expected = Success<AuthUser?>(_user);
      final repository = _FakeAuthRepository(currentUserResult: expected);

      final result = await GetCurrentUserUseCase(repository)(const NoParams());

      expect(result, same(expected));
      expect(repository.getCurrentUserCalls, 1);
    });
  });
}

const _user = AuthUser(
  id: 'user-1',
  email: 'user@example.com',
  phone: '0500000000',
  fullName: 'Mina Adly',
  isEmailConfirmed: true,
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    Result<AuthUser>? registerResult,
    Result<AuthUser>? loginResult,
    Result<void>? logoutResult,
    Result<AuthUser?>? currentUserResult,
  }) : registerResult = registerResult ?? const Success<AuthUser>(_user),
       loginResult = loginResult ?? const Success<AuthUser>(_user),
       logoutResult = logoutResult ?? const Success<void>(null),
       currentUserResult =
           currentUserResult ?? const Success<AuthUser?>(_user);

  Result<AuthUser> registerResult;
  Result<AuthUser> loginResult;
  Result<void> logoutResult;
  Result<AuthUser?> currentUserResult;

  int registerCalls = 0;
  int loginCalls = 0;
  int logoutCalls = 0;
  int getCurrentUserCalls = 0;

  String? lastRegisterFullName;
  String? lastRegisterPhone;
  String? lastRegisterEmail;
  String? lastRegisterPassword;
  String? lastLoginEmail;
  String? lastLoginPassword;

  @override
  Future<Result<AuthUser>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    registerCalls++;
    lastRegisterFullName = fullName;
    lastRegisterPhone = phone;
    lastRegisterEmail = email;
    lastRegisterPassword = password;
    return registerResult;
  }

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    lastLoginEmail = email;
    lastLoginPassword = password;
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
