import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:horus_system/features/auth/data/models/auth_user_model.dart';
import 'package:horus_system/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:horus_system/features/auth/domain/entities/auth_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;
import 'package:test/test.dart';

void main() {
  group('AuthRepositoryImpl', () {
    test(
      'register forwards inputs and maps data model to domain entity',
      () async {
        final dataSource = _FakeAuthRemoteDataSource();
        final repository = AuthRepositoryImpl(dataSource);

        final result = await repository.register(
          fullName: 'Mina Adly',
          phone: '0500000000',
          email: 'user@example.com',
          password: 'secret',
        );

        expect(result, isA<Success<AuthUser>>());
        final user = result.dataOrNull;
        expect(user?.id, _model.id);
        expect(user?.email, _model.email);
        expect(user?.phone, _model.phone);
        expect(user?.fullName, _model.fullName);
        expect(user?.isEmailConfirmed, isTrue);
        expect(dataSource.registerCalls, 1);
        expect(dataSource.lastRegisterFullName, 'Mina Adly');
        expect(dataSource.lastRegisterPhone, '0500000000');
        expect(dataSource.lastRegisterEmail, 'user@example.com');
        expect(dataSource.lastRegisterPassword, 'secret');
      },
    );

    test(
      'login forwards inputs and maps data model to domain entity',
      () async {
        final dataSource = _FakeAuthRemoteDataSource();
        final repository = AuthRepositoryImpl(dataSource);

        final result = await repository.login(
          email: 'user@example.com',
          password: 'secret',
        );

        expect(result.dataOrNull?.id, _model.id);
        expect(result.dataOrNull?.email, _model.email);
        expect(dataSource.loginCalls, 1);
        expect(dataSource.lastLoginEmail, 'user@example.com');
        expect(dataSource.lastLoginPassword, 'secret');
      },
    );

    test('logout success returns Success<void>', () async {
      final dataSource = _FakeAuthRemoteDataSource();
      final repository = AuthRepositoryImpl(dataSource);

      final result = await repository.logout();

      expect(result, isA<Success<void>>());
      expect(result.isSuccess, isTrue);
      expect(dataSource.logoutCalls, 1);
    });

    test(
      'logout unexpected exception maps to sanitized UnexpectedFailure',
      () async {
        final dataSource = _FakeAuthRemoteDataSource(
          logoutError: StateError('logout boom'),
        );
        final repository = AuthRepositoryImpl(dataSource);

        final result = await repository.logout();

        expect(result.failureOrNull, isA<UnexpectedFailure>());
        expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
        expect(result.failureOrNull?.message, isNull);
        expect(dataSource.logoutCalls, 1);
      },
    );

    test('getCurrentUser maps an authenticated model', () async {
      final dataSource = _FakeAuthRemoteDataSource();
      final repository = AuthRepositoryImpl(dataSource);

      final result = await repository.getCurrentUser();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.id, _model.id);
    });

    test('getCurrentUser preserves unauthenticated null', () async {
      final dataSource = _FakeAuthRemoteDataSource(currentUserModel: null);
      final repository = AuthRepositoryImpl(dataSource);

      final result = await repository.getCurrentUser();

      expect(result, isA<Success<AuthUser?>>());
      expect(result.dataOrNull, isNull);
    });

    test('AuthException maps semantic code without raw details', () async {
      final dataSource = _FakeAuthRemoteDataSource(
        loginError: const AuthException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      );
      final repository = AuthRepositoryImpl(dataSource);

      final result = await repository.login(
        email: 'user@example.com',
        password: 'wrong',
      );

      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull?.code, FailureCodes.authInvalidCredentials);
      expect(result.failureOrNull?.message, isNull);
    });

    test(
      'AuthException without semantic code uses sanitized fallback',
      () async {
        final dataSource = _FakeAuthRemoteDataSource(
          registerError: const AuthException(
            'Registration failed with backend detail',
            statusCode: '400',
          ),
        );
        final repository = AuthRepositoryImpl(dataSource);

        final result = await repository.register(
          fullName: 'Mina Adly',
          phone: '0500000000',
          email: 'user@example.com',
          password: 'secret',
        );

        expect(result.failureOrNull, isA<AuthFailure>());
        expect(result.failureOrNull?.code, FailureCodes.authError);
        expect(result.failureOrNull?.message, isNull);
      },
    );

    test('PostgrestException maps to sanitized ServerFailure', () async {
      final dataSource = _FakeAuthRemoteDataSource(
        registerError: const PostgrestException(
          message: 'permission denied for table user_profiles',
          code: '42501',
        ),
      );
      final repository = AuthRepositoryImpl(dataSource);

      final result = await repository.register(
        fullName: 'Mina Adly',
        phone: '0500000000',
        email: 'user@example.com',
        password: 'secret',
      );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('unexpected exceptions map to sanitized UnexpectedFailure', () async {
      final dataSource = _FakeAuthRemoteDataSource(
        currentUserError: StateError('boom'),
      );
      final repository = AuthRepositoryImpl(dataSource);

      final result = await repository.getCurrentUser();

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
    });
  });
}

const _model = AuthUserModel(
  id: 'user-1',
  email: 'user@example.com',
  phone: '0500000000',
  fullName: 'Mina Adly',
  isEmailConfirmed: true,
);

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  _FakeAuthRemoteDataSource({
    AuthUserModel? registerModel,
    AuthUserModel? loginModel,
    this.currentUserModel = _model,
    this.registerError,
    this.loginError,
    this.logoutError,
    this.currentUserError,
  }) : registerModel = registerModel ?? _model,
       loginModel = loginModel ?? _model;

  final AuthUserModel registerModel;
  final AuthUserModel loginModel;
  final AuthUserModel? currentUserModel;
  final Object? registerError;
  final Object? loginError;
  final Object? logoutError;
  final Object? currentUserError;

  int registerCalls = 0;
  int loginCalls = 0;
  int logoutCalls = 0;
  String? lastRegisterFullName;
  String? lastRegisterPhone;
  String? lastRegisterEmail;
  String? lastRegisterPassword;
  String? lastLoginEmail;
  String? lastLoginPassword;

  @override
  Future<AuthUserModel> register({
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

    if (registerError != null) throw registerError!;
    return registerModel;
  }

  @override
  Future<AuthUserModel> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    lastLoginEmail = email;
    lastLoginPassword = password;

    if (loginError != null) throw loginError!;
    return loginModel;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutError != null) throw logoutError!;
  }

  @override
  Future<AuthUserModel?> getCurrentUser() async {
    if (currentUserError != null) throw currentUserError!;
    return currentUserModel;
  }
}
