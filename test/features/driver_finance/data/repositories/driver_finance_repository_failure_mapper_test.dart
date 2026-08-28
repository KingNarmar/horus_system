import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/driver_finance/data/repositories/driver_finance_repository_failure_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('DriverFinanceRepositoryFailureMapper', () {
    const mapper = DriverFinanceRepositoryFailureMapper();

    test('sanitizes movement Postgrest backend payload', () {
      const error = PostgrestException(
        message: 'movement denied',
        code: '42501',
        details: 'backend details',
        hint: 'backend hint',
      );

      final failure = mapper.fromMovementPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
      expect(failure.code, isNot(error.code));
      expect(failure.message, isNot(error.message));
    });

    test('maps movement Postgrest without code to the same server failure', () {
      const error = PostgrestException(message: 'database error');

      final failure = mapper.fromMovementPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });

    test('preserves balance 42501 as sanitized Driver Finance permission', () {
      const error = PostgrestException(
        message: 'permission denied',
        code: '42501',
        details: 'backend details',
        hint: 'backend hint',
      );

      final failure = mapper.fromBalancePostgrest(error);

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, FailureCodes.permissionDriverFinanceView);
      expect(failure.message, isNull);
    });

    test('sanitizes other balance Postgrest errors to server failure', () {
      const error = PostgrestException(
        message: 'database unavailable',
        code: 'PGRST500',
        details: 'backend details',
        hint: 'backend hint',
      );

      final failure = mapper.fromBalancePostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
      expect(failure.code, isNot(error.code));
      expect(failure.message, isNot(error.message));
    });

    test('sanitizes unexpected runtime text', () {
      final error = Exception('unexpected runtime details');

      final failure = mapper.fromUnexpected(error);

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.code, FailureCodes.unexpectedError);
      expect(failure.message, isNull);
      expect(failure.message, isNot(error.toString()));
    });
  });
}
