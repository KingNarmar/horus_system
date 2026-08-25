import 'package:horus_system/core/context/current_company_provider.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/data/repositories/company_context_repository_failure_mapper.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyContextRepositoryFailureMapper', () {
    const mapper = CompanyContextRepositoryFailureMapper();

    test('sanitizes auth exceptions', () {
      final failure = mapper.fromAuthException(
        AuthException('secret authentication detail', statusCode: '401'),
      );

      expect(failure, isA<AuthFailure>());
      expect(failure.code, CompanyFailureCodes.authRequired);
      expect(failure.message, isNull);
    });

    test('sanitizes PostgREST exceptions', () {
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

    test('sanitizes missing company context exceptions', () {
      final failure = mapper.fromMissingCompanyContext(
        const MissingCompanyContextException(
          message: 'secret provider detail',
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.code, FailureCodes.validationCompanyContextRequired);
      expect(failure.message, isNull);
    });

    test('sanitizes unexpected exceptions', () {
      final failure = mapper.fromUnexpected(
        StateError('secret internal exception text'),
      );

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, isNull);
    });
  });
}
