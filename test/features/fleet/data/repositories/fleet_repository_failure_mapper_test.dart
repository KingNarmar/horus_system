import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/fleet/data/repositories/fleet_repository_failure_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('FleetRepositoryFailureMapper', () {
    const mapper = FleetRepositoryFailureMapper();

    test('sanitizes Postgrest code and message', () {
      const error = PostgrestException(
        message: 'permission denied',
        code: '42501',
      );

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });

    test('uses server fallback code when Postgrest code is missing', () {
      const error = PostgrestException(message: 'server failure');

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });

    test('sanitizes unexpected errors', () {
      final failure = mapper.fromUnexpected(StateError('unexpected failure'));

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.code, FailureCodes.unexpectedError);
      expect(failure.message, isNull);
    });
  });
}
