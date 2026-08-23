import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/driver_finance/data/repositories/driver_finance_repository_failure_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('DriverFinanceRepositoryFailureMapper', () {
    const mapper = DriverFinanceRepositoryFailureMapper();

    test('maps movement Postgrest errors to server failure', () {
      const error = PostgrestException(
        message: 'movement denied',
        code: '42501',
      );

      final failure = mapper.fromMovementPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, '42501');
      expect(failure.message, 'movement denied');
    });

    test('falls back to server error when Postgrest code is absent', () {
      const error = PostgrestException(message: 'database error');

      final failure = mapper.fromMovementPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, 'database error');
    });

    test('maps balance 42501 to Driver Finance view permission failure', () {
      const error = PostgrestException(
        message: 'permission denied',
        code: '42501',
      );

      final failure = mapper.fromBalancePostgrest(error);

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, FailureCodes.permissionDriverFinanceView);
      expect(failure.message, 'Driver finance access is not allowed.');
    });

    test('maps other balance Postgrest errors to server failure', () {
      const error = PostgrestException(
        message: 'database unavailable',
        code: 'PGRST500',
      );

      final failure = mapper.fromBalancePostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, 'PGRST500');
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
