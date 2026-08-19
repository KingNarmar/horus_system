import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/driver_settlements/data/repositories/driver_settlement_repository_failure_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('DriverSettlementRepositoryFailureMapper', () {
    const mapper = DriverSettlementRepositoryFailureMapper();

    test('preserves Postgrest code and message', () {
      const error = PostgrestException(
        message: 'permission denied',
        code: '42501',
      );

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, '42501');
      expect(failure.message, 'permission denied');
    });

    test('falls back to server error when Postgrest code is absent', () {
      const error = PostgrestException(message: 'database error');

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, 'database error');
    });

    test('preserves unexpected error text', () {
      final error = Exception('unexpected');

      final failure = mapper.fromUnexpected(error);

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, error.toString());
    });
  });
}
