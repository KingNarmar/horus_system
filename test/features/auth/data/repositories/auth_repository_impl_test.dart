import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:horus_system/features/auth/data/models/auth_user_model.dart';
import 'package:horus_system/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:test/test.dart';

void main() {
  group('AuthRepositoryImpl', () {
    test('register maps data model to domain entity', () async {
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
    });

    test('login maps data model to domain entity', () async {
      final dataSource = _FakeAuthRemoteDataSource();
      final repository = AuthRepositoryImpl(dataSource);

      final result = await repository.login(
        email: 'user@example.com',
        password: 'secret',
      );

      expect(result.dataOrNull?.id, _model.id);
      expect(result.dataOrNull?.email, _model.email);
    });

    test('logout success returns Success<void>', () async {
      final dataSource = _FakeAuthRemoteDataSource();
      final repository = AuthRepositoryImpl(dataSource);

      final result = await repository.logout();

      expect(result, isA<Success<void>>());
      expect(result.isSuccess, isTrue);
      expect(dataSource.logoutCalls, 1);
    });

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

    test('AuthException maps to AuthFailure with status code', () async {
      final dataSource = _FakeAuthRemoteDataSource(
        loginError: AuthException(
          'Invalid credentials',
          statusCode: '401',
        ),
      );
      final repository = AuthRepositoryImpl(dataSource);

      final result = await repository.login(
        email: 'user@example.com',
        password: 'wrong',
      );

      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull?.code, '401');
      expect(result.failureOrNull?.message, 'Invalid credentials');
    });

    test('AuthException without status code uses existing fallback code', () async {
      final dataSource = _FakeAuthRemoteDataSource(
        registerError: const AuthException('Registration failed'),
      );
      final repository = AuthRepositoryImpl(dataSource);

      final result = await repository.register(
        fullName: 'Mina Adly',
        phone: '0500000000',
        email: 'user@example.com',
        password: 'secret',
      );

      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull?.code, 'auth_error');
    });

    test('unexpected exceptions map to UnexpectedFailure', () async {
      final dataSource = _FakeAuthRemoteDataSource(
        currentUserError: StateError('boom'),
      );
      final repository = AuthRepositoryImpl(dataSource);

      final result = await repository.getCurrentUser();

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.message, contains('boom'));
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

  int logoutCalls = 0;

  @override
  Future<AuthUserModel> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    if (registerError != null) throw registerError!;
    return registerModel;
  }

  @override
  Future<AuthUserModel> login({
    required String email,
    required String password,
  }) async {
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
