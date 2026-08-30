import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/subscriptions/data/repositories/subscriptions_repository_failure_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('SubscriptionsRepositoryFailureMapper', () {
    const mapper = SubscriptionsRepositoryFailureMapper();

    test('maps 42501 to sanitized subscriptions view permission failure', () {
      const error = PostgrestException(
        message: 'permission denied',
        code: '42501',
        details: 'internal permission details',
        hint: 'internal permission hint',
      );

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, FailureCodes.permissionSubscriptionsView);
      expect(failure.message, isNull);
    });

    test('maps other Postgrest errors to sanitized server failure', () {
      const error = PostgrestException(
        message: 'database unavailable',
        code: 'PGRST500',
        details: 'internal database details',
        hint: 'internal database hint',
      );

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
      expect(failure.message, isNot(error.message));
      expect(failure.message, isNot(error.details));
      expect(failure.message, isNot(error.hint));
    });

    test('maps unexpected error without runtime text', () {
      final error = StateError('unexpected runtime details');

      final failure = mapper.fromUnexpected(error);

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.code, FailureCodes.unexpectedError);
      expect(failure.message, isNull);
      expect(failure.message, isNot(error.toString()));
    });
  });
}
