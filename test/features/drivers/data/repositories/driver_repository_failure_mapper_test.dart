import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/drivers/data/repositories/driver_repository_failure_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  const mapper = DriverRepositoryFailureMapper();

  group('DriverRepositoryFailureMapper', () {
    test('sanitizes PostgREST failures', () {
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

    test('maps oversized Storage failures to the existing validation code', () {
      final failure = mapper.fromStorage(
        const StorageException('Payload is too large', statusCode: '413'),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.code, FailureCodes.validationDriverImageTooLarge);
    });

    test(
      'maps unsupported Storage failures to the existing validation code',
      () {
        final failure = mapper.fromStorage(
          const StorageException('Unsupported MIME type', statusCode: '415'),
        );

        expect(failure, isA<ValidationFailure>());
        expect(failure.code, FailureCodes.validationDriverImageTypeUnsupported);
      },
    );

    test('sanitizes other Storage failures', () {
      final failure = mapper.fromStorage(
        const StorageException(
          'secret storage implementation detail',
          statusCode: '500',
        ),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });

    test('sanitizes unexpected failures', () {
      final failure = mapper.fromUnexpected(
        StateError('secret implementation detail'),
      );

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.code, FailureCodes.unexpectedError);
      expect(failure.message, isNull);
    });
  });
}
