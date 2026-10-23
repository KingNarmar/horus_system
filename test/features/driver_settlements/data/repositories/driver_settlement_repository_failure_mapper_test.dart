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

    test('maps atomic RPC authorization failures to typed permission', () {
      const error = PostgrestException(
        message: 'private actor details',
        code: 'P2813',
      );
      final failure = mapper.fromPostgrest(error);
      expect(failure, isA<PermissionFailure>());
      expect(failure.code, FailureCodes.permissionDriverSettlementsManagement);
      expect(failure.message, isNull);
    });

    test('maps rejected atomic draft payload to localized validation code', () {
      const error = PostgrestException(message: 'server fields', code: 'P2814');
      final failure = mapper.fromPostgrest(error);
      expect(failure, isA<ValidationFailure>());
      expect(
        failure.code,
        DriverSettlementFailureCodes.validationDraftPayloadInvalid,
      );
      expect(failure.message, isNull);
    });

    test('maps stale canonical sources to a recoverable conflict', () {
      const error = PostgrestException(
        message: 'private source data',
        code: 'P2815',
      );
      final failure = mapper.fromPostgrest(error);
      expect(failure, isA<ConflictFailure>());
      expect(
        failure.code,
        DriverSettlementFailureCodes.conflictSourceSnapshotChanged,
      );
      expect(failure.message, isNull);
    });

    test('maps stale compensation without exposing its amount', () {
      const error = PostgrestException(
        message: 'private salary data',
        code: 'P2816',
      );
      final failure = mapper.fromPostgrest(error);
      expect(failure, isA<ConflictFailure>());
      expect(
        failure.code,
        DriverSettlementFailureCodes.conflictCompensationChanged,
      );
      expect(failure.message, isNull);
    });

    test('rejects mismatched exact money as a typed validation failure', () {
      const error = PostgrestException(
        message: 'private currency amount',
        code: 'P2817',
      );
      final failure = mapper.fromPostgrest(error);
      expect(failure, isA<ValidationFailure>());
      expect(
        failure.code,
        DriverSettlementFailureCodes.validationExactMoneyMismatch,
      );
      expect(failure.message, isNull);
    });

    test('rejects tampered aggregate money without exposing details', () {
      const error = PostgrestException(
        message: 'private totals',
        code: 'P2818',
      );
      final failure = mapper.fromPostgrest(error);
      expect(failure, isA<ValidationFailure>());
      expect(
        failure.code,
        DriverSettlementFailureCodes.validationFinancialTotalsMismatch,
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
