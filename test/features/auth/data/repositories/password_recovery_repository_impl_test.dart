import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:horus_system/features/auth/data/models/auth_user_model.dart';
import 'package:horus_system/features/auth/data/repositories/password_recovery_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:test/test.dart';

void main() {
  group('PasswordRecoveryRepositoryImpl', () {
    final redirectUri = Uri.https(
      'kingnarmar.com',
      '/horus/reset-password',
    );

    test('forwards email and configured redirect to data source', () async {
      final dataSource = _FakeAuthRemoteDataSource();
      final repository = PasswordRecoveryRepositoryImpl(
        remoteDataSource: dataSource,
        recoveryRedirectUri: redirectUri,
      );

      final result = await repository.requestPasswordRecovery(
        email: 'user@example.com',
      );

      expect(result, isA<Success<void>>());
      expect(dataSource.recoveryCalls, 1);
      expect(dataSource.lastRecoveryEmail, 'user@example.com');
      expect(
        dataSource.lastRecoveryRedirectTo,
        'https://kingnarmar.com/horus/reset-password',
      );
    });

    test('maps rate limit without exposing backend message', () async {
      final dataSource = _FakeAuthRemoteDataSource(
        recoveryError: const AuthException(
          'private provider detail',
          statusCode: '429',
          code: 'over_email_send_rate_limit',
        ),
      );
      final repository = PasswordRecoveryRepositoryImpl(
        remoteDataSource: dataSource,
        recoveryRedirectUri: redirectUri,
      );

      final result = await repository.requestPasswordRecovery(
        email: 'user@example.com',
      );

      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull?.code, FailureCodes.authRateLimited);
      expect(result.failureOrNull?.message, isNull);
    });

    test('sanitizes unexpected exceptions', () async {
      final dataSource = _FakeAuthRemoteDataSource(
        recoveryError: StateError('secret detail'),
      );
      final repository = PasswordRecoveryRepositoryImpl(
        remoteDataSource: dataSource,
        recoveryRedirectUri: redirectUri,
      );

      final result = await repository.requestPasswordRecovery(
        email: 'user@example.com',
      );

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
    });
  });
}

final class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  _FakeAuthRemoteDataSource({this.recoveryError});

  final Object? recoveryError;
  int recoveryCalls = 0;
  String? lastRecoveryEmail;
  String? lastRecoveryRedirectTo;

  @override
  Future<void> requestPasswordRecovery({
    required String email,
    required String redirectTo,
  }) async {
    recoveryCalls++;
    lastRecoveryEmail = email;
    lastRecoveryRedirectTo = redirectTo;
    if (recoveryError != null) throw recoveryError!;
  }

  @override
  Future<AuthUserModel?> getCurrentUser() => throw UnimplementedError();

  @override
  Future<AuthUserModel> login({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> logout() => throw UnimplementedError();

  @override
  Future<AuthUserModel> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) => throw UnimplementedError();
}
