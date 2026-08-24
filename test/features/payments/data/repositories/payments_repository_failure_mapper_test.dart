import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/payments/data/constants/payments_db_constants.dart';
import 'package:horus_system/features/payments/data/repositories/payments_repository_failure_mapper.dart';
import 'package:horus_system/features/payments/domain/failures/payment_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentsRepositoryFailureMapper', () {
    const mapper = PaymentsRepositoryFailureMapper();

    test('maps auth exceptions to auth-required failure', () {
      final failure = mapper.fromAuthException(AuthException('expired'));

      expect(failure, isA<AuthFailure>());
      expect(failure.code, CompanyFailureCodes.authRequired);
      expect(failure.message, isNull);
    });

    test('maps payment permission using supplied domain code', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'permission denied',
          code: PaymentsRpcErrorCodes.permissionDenied,
        ),
        permissionCode: PaymentFailureCodes.permissionManage,
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, PaymentFailureCodes.permissionManage);
    });

    test('maps direct table privilege denial using supplied domain code', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(message: 'permission denied', code: '42501'),
        permissionCode: PaymentFailureCodes.permissionView,
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, PaymentFailureCodes.permissionView);
    });

    test('preserves all typed not-found mappings', () {
      const cases = <String, String>{
        PaymentsRpcErrorCodes.invoiceNotFound:
            PaymentFailureCodes.invoiceNotFound,
        PaymentsRpcErrorCodes.paymentMethodNotFound:
            PaymentFailureCodes.paymentMethodNotFound,
        PaymentsRpcErrorCodes.companyNotFound: CompanyFailureCodes.notFound,
      };

      for (final entry in cases.entries) {
        final failure = mapper.fromPostgrest(
          PostgrestException(message: 'not found', code: entry.key),
          permissionCode: PaymentFailureCodes.permissionManage,
        );

        expect(failure, isA<NotFoundFailure>());
        expect(failure.code, entry.value);
      }
    });

    test('preserves all typed validation mappings', () {
      const cases = <String, String>{
        PaymentsRpcErrorCodes.amountNotPositive:
            PaymentFailureCodes.validationAmountPositive,
        PaymentsRpcErrorCodes.currencyMismatch:
            PaymentFailureCodes.validationCurrencyMismatch,
        PaymentsRpcErrorCodes.paymentDateRequired:
            PaymentFailureCodes.validationDateRequired,
        PaymentsRpcErrorCodes.paymentDateBeforeInvoice:
            PaymentFailureCodes.validationDateBeforeInvoice,
        PaymentsRpcErrorCodes.paymentDateFuture:
            PaymentFailureCodes.validationDateFuture,
        PaymentsRpcErrorCodes.paymentMethodRequired:
            PaymentFailureCodes.validationPaymentMethodIdRequired,
        PaymentsRpcErrorCodes.currencyRequired:
            PaymentFailureCodes.validationCurrencyInvalid,
      };

      for (final entry in cases.entries) {
        final failure = mapper.fromPostgrest(
          PostgrestException(message: 'validation', code: entry.key),
          permissionCode: PaymentFailureCodes.permissionManage,
        );

        expect(failure, isA<ValidationFailure>());
        expect(failure.code, entry.value);
      }
    });

    test('preserves all typed conflict mappings', () {
      const cases = <String, String>{
        PaymentsRpcErrorCodes.invoiceStatusInvalid:
            PaymentFailureCodes.conflictInvoiceStatusInvalid,
        PaymentsRpcErrorCodes.paymentMethodInactive:
            PaymentFailureCodes.conflictPaymentMethodInactive,
        PaymentsRpcErrorCodes.overpayment:
            PaymentFailureCodes.conflictOverpayment,
        PaymentsRpcErrorCodes.invoiceBalanceInvalid:
            PaymentFailureCodes.conflictInvoiceBalanceInvalid,
        PaymentsRpcErrorCodes.invoiceLinesRequired:
            PaymentFailureCodes.conflictInvoiceLinesRequired,
        PaymentsRpcErrorCodes.tripStateInvalid:
            PaymentFailureCodes.conflictTripStateInvalid,
        PaymentsRpcErrorCodes.regionalSettingsNotConfigured:
            CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
      };

      for (final entry in cases.entries) {
        final failure = mapper.fromPostgrest(
          PostgrestException(message: 'conflict', code: entry.key),
          permissionCode: PaymentFailureCodes.permissionManage,
        );

        expect(failure, isA<ConflictFailure>());
        expect(failure.code, entry.value);
        expect(failure.message, isNull);
      }
    });

    test('sanitizes unknown persistence failures', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'secret backend details',
          code: 'XX999',
          details: 'private schema detail',
          hint: 'internal hint',
        ),
        permissionCode: PaymentFailureCodes.permissionView,
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });

    test('maps corrupt persisted format failures to generic server failure', () {
      final failure = mapper.fromFormatException(
        const FormatException('invalid persisted payment'),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });

    test('maps unexpected failures without exposing internal text', () {
      final failure = mapper.fromUnexpected(StateError('secret internal text'));

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, isNull);
    });
  });
}
