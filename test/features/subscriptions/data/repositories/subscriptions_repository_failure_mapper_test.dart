import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/subscriptions/data/repositories/subscriptions_repository_failure_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('SubscriptionsRepositoryFailureMapper', () {
    const mapper = SubscriptionsRepositoryFailureMapper();

    test('maps 42501 to stable subscriptions view permission failure', () {
      const error = PostgrestException(
        message: 'permission denied',
        code: '42501',
      );

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, FailureCodes.permissionSubscriptionsView);
      expect(failure.message, 'Subscription view is not allowed.');
    });

    test('maps other Postgrest errors to server failure', () {
      const error = PostgrestException(
        message: 'database unavailable',
        code: 'PGRST500',
      );

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, 'database unavailable');
    });

    test('preserves unexpected error text', () {
      final error = Exception('unexpected');

      final failure = mapper.fromUnexpected(error);

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, error.toString());
    });
  });
}
