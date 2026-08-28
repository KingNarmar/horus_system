import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/auth/data/repositories/auth_repository_failure_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;
import 'package:test/test.dart';

void main() {
  group('AuthRepositoryFailureMapper', () {
    const mapper = AuthRepositoryFailureMapper();

    const authCases = <String, String>{
      'invalid_credentials': FailureCodes.authInvalidCredentials,
      'email_not_confirmed': FailureCodes.authEmailNotConfirmed,
      'email_exists': FailureCodes.authAccountAlreadyExists,
      'user_already_exists': FailureCodes.authAccountAlreadyExists,
      'weak_password': FailureCodes.authWeakPassword,
      'email_address_invalid': FailureCodes.authInvalidEmail,
      'over_request_rate_limit': FailureCodes.authRateLimited,
      'over_email_send_rate_limit': FailureCodes.authRateLimited,
    };

    for (final entry in authCases.entries) {
      test('maps ${entry.key} to stable Auth failure code', () {
        final error = AuthException(
          'raw backend auth message',
          statusCode: '401',
          code: entry.key,
        );

        final failure = mapper.fromException(error);

        expect(failure, isA<AuthFailure>());
        expect(failure.code, entry.value);
        expect(failure.code, isNot('401'));
        expect(failure.message, isNull);
      });
    }

    test('unknown AuthException uses sanitized auth fallback', () {
      const error = AuthException(
        'internal authentication detail',
        statusCode: '503',
        code: 'future_auth_code',
      );

      final failure = mapper.fromException(error);

      expect(failure, isA<AuthFailure>());
      expect(failure.code, FailureCodes.authError);
      expect(failure.message, isNull);
    });

    test('AuthException without code uses sanitized auth fallback', () {
      const error = AuthException(
        'registration failed with private backend detail',
        statusCode: '400',
      );

      final failure = mapper.fromException(error);

      expect(failure, isA<AuthFailure>());
      expect(failure.code, FailureCodes.authError);
      expect(failure.message, isNull);
    });

    test('sanitizes Postgrest failures from auth persistence work', () {
      const error = PostgrestException(
        message: 'permission denied for table user_profiles',
        code: '42501',
        details: 'private persistence detail',
        hint: 'private database hint',
      );

      final failure = mapper.fromException(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });

    test('sanitizes unexpected errors', () {
      final failure = mapper.fromException(StateError('unexpected secret'));

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.code, FailureCodes.unexpectedError);
      expect(failure.message, isNull);
    });
  });
}
