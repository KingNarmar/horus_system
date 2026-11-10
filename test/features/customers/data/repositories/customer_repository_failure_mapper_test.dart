import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/subscriptions/domain/failures/quota_failure_codes.dart';
import 'package:horus_system/features/customers/data/repositories/customer_repository_failure_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  test('maps only its own P2860 quota rejection to a sanitized conflict', () {
    const mapper = CustomerRepositoryFailureMapper();
    final matched = mapper.fromPostgrest(
      const PostgrestException(
        code: 'P2860',
        message: QuotaFailureCodes.customersReached,
        details: 'secret backend detail',
      ),
    );
    expect(matched, isA<ConflictFailure>());
    expect(matched.code, QuotaFailureCodes.customersReached);
    expect(matched.message, isNull);

    final spoofed = mapper.fromPostgrest(
      const PostgrestException(
        code: 'P2860',
        message: QuotaFailureCodes.companyUsersReached,
      ),
    );
    expect(spoofed, isA<ServerFailure>());
    expect(spoofed.message, isNull);
  });

  group('CustomerRepositoryFailureMapper', () {
    const mapper = CustomerRepositoryFailureMapper();

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
      expect(failure.code, FailureCodes.unexpectedError);
      expect(failure.message, isNull);
    });
  });
}
