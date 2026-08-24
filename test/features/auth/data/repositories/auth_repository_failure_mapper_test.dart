import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/features/auth/data/repositories/auth_repository_failure_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:test/test.dart';

void main() {
  group('AuthRepositoryFailureMapper', () {
    const mapper = AuthRepositoryFailureMapper();

    test('preserves AuthException status code and message', () {
      final error = AuthException('Invalid credentials', statusCode: '401');

      final failure = mapper.fromAuthException(error);

      expect(failure, isA<AuthFailure>());
      expect(failure.code, '401');
      expect(failure.message, 'Invalid credentials');
    });

    test('uses existing auth_error fallback when status code is absent', () {
      final error = AuthException('Registration failed');

      final failure = mapper.fromAuthException(error);

      expect(failure, isA<AuthFailure>());
      expect(failure.code, 'auth_error');
      expect(failure.message, 'Registration failed');
    });

    test('preserves unexpected error text', () {
      final error = StateError('boom');

      final failure = mapper.fromUnexpected(error);

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, error.toString());
    });
  });
}
