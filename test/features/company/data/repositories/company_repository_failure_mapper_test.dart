import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/data/constants/company_rpc_error_codes.dart';
import 'package:horus_system/features/company/data/repositories/company_repository_failure_mapper.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyRepositoryFailureMapper', () {
    const mapper = CompanyRepositoryFailureMapper();

    test('maps auth exceptions to stable auth-required failure', () {
      final failure = mapper.fromAuthException(
        AuthException('secret authentication detail'),
      );

      expect(failure, isA<AuthFailure>());
      expect(failure.code, CompanyFailureCodes.authRequired);
      expect(failure.message, isNull);
    });

    test('maps onboarding timezone rejection to typed validation failure', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'company_business_timezone_invalid',
          code: CompanyRpcErrorCodes.onboardingBusinessTimezoneInvalid,
          details: 'private database details',
          hint: 'internal database hint',
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect(
        failure.code,
        CompanyFailureCodes.validationBusinessTimezoneInvalid,
      );
      expect(failure.message, isNull);
    });

    test('sanitizes PostgREST persistence failures', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'secret backend message',
          code: 'XX999',
          details: 'private database details',
          hint: 'internal database hint',
        ),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });

    test('sanitizes unexpected failures', () {
      final failure = mapper.fromUnexpected(
        StateError('secret internal exception text'),
      );

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, isNull);
    });
  });
}
