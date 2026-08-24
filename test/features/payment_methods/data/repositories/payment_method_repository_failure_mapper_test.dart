import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/payment_methods/data/repositories/payment_method_repository_failure_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('PaymentMethodRepositoryFailureMapper', () {
    const mapper = PaymentMethodRepositoryFailureMapper();

    test('maps duplicate-name database error to stable conflict failure', () {
      const error = PostgrestException(
        message: 'duplicate internal wording',
        code: '23505',
      );

      final failure = mapper.fromPostgrest(
        error,
        permissionCode: FailureCodes.permissionPaymentMethodsManagement,
      );

      expect(failure, isA<ConflictFailure>());
      expect(failure.code, FailureCodes.conflictPaymentMethodDuplicateName);
      expect(
        failure.message,
        'A payment method with this name already exists.',
      );
    });

    test('maps missing-row error to stable not-found failure', () {
      const error = PostgrestException(
        message: 'not found internal wording',
        code: 'PGRST116',
      );

      final failure = mapper.fromPostgrest(
        error,
        permissionCode: FailureCodes.permissionPaymentMethodsManagement,
      );

      expect(failure, isA<NotFoundFailure>());
      expect(failure.code, FailureCodes.paymentMethodNotFound);
      expect(failure.message, 'Payment method was not found.');
    });

    test('maps 42501 using the supplied operation permission code', () {
      const error = PostgrestException(
        message: 'permission denied',
        code: '42501',
      );

      final failure = mapper.fromPostgrest(
        error,
        permissionCode: FailureCodes.permissionPaymentMethodsView,
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, FailureCodes.permissionPaymentMethodsView);
      expect(failure.message, 'Payment method access is not allowed.');
    });

    test('maps other Postgrest errors to server failure', () {
      const error = PostgrestException(
        message: 'database unavailable',
        code: 'PGRST500',
      );

      final failure = mapper.fromPostgrest(
        error,
        permissionCode: FailureCodes.permissionPaymentMethodsView,
      );

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
