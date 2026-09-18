import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/trips/data/constants/trip_db_contract.dart';
import 'package:horus_system/features/trips/data/repositories/trip_repository_failure_mapper.dart';
import 'package:horus_system/features/trips/domain/failures/trip_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('TripRepositoryFailureMapper', () {
    const mapper = TripRepositoryFailureMapper();

    test('maps management permission denial to typed failure', () {
      const error = PostgrestException(
        message: 'trip_management_permission_denied',
        code: TripDbErrorCodes.managementPermissionDenied,
      );

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, FailureCodes.permissionTripsManagement);
      expect(failure.message, isNull);
    });

    test('maps status permission denial to typed failure', () {
      const error = PostgrestException(
        message: 'trip_status_permission_denied',
        code: TripDbErrorCodes.statusPermissionDenied,
      );

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, FailureCodes.permissionTripStatusUpdate);
      expect(failure.message, isNull);
    });

    test('maps missing trip to typed not-found failure', () {
      const error = PostgrestException(
        message: 'trip_not_found',
        code: TripDbErrorCodes.notFound,
      );

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<NotFoundFailure>());
      expect(failure.code, TripFailureCodes.notFound);
      expect(failure.message, isNull);
    });

    test('maps RPC temporal validation to stable validation failure', () {
      const error = PostgrestException(
        message: 'trip_delivery_before_loading',
        code: TripDbErrorCodes.temporalOrderInvalid,
      );

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<ValidationFailure>());
      expect(failure.code, FailureCodes.validationTripDeliveryBeforeLoading);
      expect(failure.message, isNull);
    });

    for (final constraint in [
      TripDbConstraints.scheduledDeliveryNotBeforeLoading,
      TripDbConstraints.actualDeliveryNotBeforeLoading,
    ]) {
      test('maps temporal check violation for $constraint', () {
        final error = PostgrestException(
          message: 'new row violates check constraint "$constraint"',
          code: TripDbErrorCodes.checkViolation,
          details: 'sensitive row detail',
        );

        final failure = mapper.fromPostgrest(error);

        expect(failure, isA<ValidationFailure>());
        expect(failure.code, FailureCodes.validationTripDeliveryBeforeLoading);
        expect(failure.message, isNull);
      });
    }

    test('sanitizes unrelated Postgrest failures to stable server error', () {
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

    test('uses stable server error when Postgrest code is absent', () {
      const error = PostgrestException(message: 'database error');

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });

    test('sanitizes unexpected failures', () {
      final error = Exception('unexpected internal detail');

      final failure = mapper.fromUnexpected(error);

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.code, FailureCodes.unexpectedError);
      expect(failure.message, isNull);
      expect(failure.message, isNot(error.toString()));
    });
  });
}
