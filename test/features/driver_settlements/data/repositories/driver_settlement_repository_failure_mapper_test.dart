import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/driver_settlements/data/repositories/driver_settlement_repository_failure_mapper.dart';
import 'package:horus_system/features/driver_settlements/domain/failures/driver_settlement_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('DriverSettlementRepositoryFailureMapper', () {
    const mapper = DriverSettlementRepositoryFailureMapper();

    test('sanitizes Postgrest failures to stable server error', () {
      const error = PostgrestException(
        message: 'permission denied',
        code: '42501',
        details: 'sensitive details',
        hint: 'sensitive hint',
      );

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
      expect(failure.code, isNot(error.code));
      expect(failure.message, isNot(error.message));
    });

    test('maps stale finalized expense sources to sanitized conflict', () {
      const error = PostgrestException(
        message: 'sensitive source details',
        code: 'P2812',
      );
      final failure = mapper.fromPostgrest(error);
      expect(failure, isA<ConflictFailure>());
      expect(
        failure.code,
        DriverSettlementFailureCodes.conflictExpenseSourceInvalid,
      );
      expect(failure.message, isNull);
    });

    test('uses stable server error when Postgrest code is absent', () {
      const error = PostgrestException(message: 'database error');

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });

    test('sanitizes unexpected failures without exposing runtime text', () {
      final error = Exception('unexpected internal detail');

      final failure = mapper.fromUnexpected(error);

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.code, FailureCodes.unexpectedError);
      expect(failure.message, isNull);
      expect(failure.message, isNot(error.toString()));
    });
  });
}
