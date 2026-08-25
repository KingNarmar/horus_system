import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/data/repositories/company_users_repository_failure_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyUsersRepositoryFailureMapper', () {
    const mapper = CompanyUsersRepositoryFailureMapper();

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
