import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/payment_methods/data/repositories/payment_method_repository_failure_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('PaymentMethodRepositoryFailureMapper', () {
    const mapper = PaymentMethodRepositoryFailureMapper();

    test('maps duplicate-name database error without backend text', () {
      const error = PostgrestException(
        message: 'duplicate internal wording',
        code: '23505',
        details: 'duplicate details',
        hint: 'duplicate hint',
      );

      final failure = mapper.fromPostgrest(
        error,
        permissionCode: FailureCodes.permissionPaymentMethodsManagement,
      );

      expect(failure, isA<ConflictFailure>());
      expect(failure.code, FailureCodes.conflictPaymentMethodDuplicateName);
      expect(failure.message, isNull);
    });

    test('maps missing-row error without backend text', () {
      const error = PostgrestException(
        message: 'not found internal wording',
        code: 'PGRST116',
        details: 'not found details',
        hint: 'not found hint',
      );

      final failure = mapper.fromPostgrest(
        error,
        permissionCode: FailureCodes.permissionPaymentMethodsManagement,
      );

      expect(failure, isA<NotFoundFailure>());
      expect(failure.code, FailureCodes.paymentMethodNotFound);
      expect(failure.message, isNull);
    });

    test('maps 42501 using supplied permission code without backend text', () {
      const error = PostgrestException(
        message: 'permission denied',
        code: '42501',
        details: 'permission details',
        hint: 'permission hint',
      );

      final failure = mapper.fromPostgrest(
        error,
        permissionCode: FailureCodes.permissionPaymentMethodsView,
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, FailureCodes.permissionPaymentMethodsView);
      expect(failure.message, isNull);
    });

    test('maps other Postgrest errors to sanitized server failure', () {
      const error = PostgrestException(
        message: 'database unavailable',
        code: 'PGRST500',
        details: 'internal database details',
        hint: 'internal database hint',
      );

      final failure = mapper.fromPostgrest(
        error,
        permissionCode: FailureCodes.permissionPaymentMethodsView,
      );

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
