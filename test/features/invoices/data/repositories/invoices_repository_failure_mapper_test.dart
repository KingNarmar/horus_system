import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/invoices/data/constants/invoices_rpc_error_codes.dart';
import 'package:horus_system/features/invoices/data/repositories/invoices_repository_failure_mapper.dart';
import 'package:horus_system/features/invoices/domain/failures/invoice_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('InvoicesRepositoryFailureMapper', () {
    const mapper = InvoicesRepositoryFailureMapper();

    test('maps auth exceptions to the existing auth-required failure', () {
      final failure = mapper.fromAuthException(AuthException('expired'));

      expect(failure, isA<AuthFailure>());
      expect(failure.code, CompanyFailureCodes.authRequired);
      expect(failure.message, isNull);
    });

    test('maps operation permission using the supplied domain code', () {
      final failure = mapper.fromPostgrest(
        PostgrestException(
          message: 'permission denied',
          code: InvoicesRpcErrorCodes.permissionDenied,
        ),
        permissionCode: FailureCodes.permissionInvoicesIssue,
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, FailureCodes.permissionInvoicesIssue);
    });

    test('maps missing regional settings without exposing DB text', () {
      final failure = mapper.fromPostgrest(
        PostgrestException(
          message: 'internal database wording',
          code: InvoicesRpcErrorCodes.regionalSettingsNotConfigured,
        ),
        permissionCode: FailureCodes.permissionInvoicesManagement,
      );

      expect(failure, isA<ConflictFailure>());
      expect(
        failure.code,
        CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
      );
      expect(failure.message, isNull);
    });

    test('maps prefix validation independently from currency mismatch', () {
      final failure = mapper.fromPostgrest(
        PostgrestException(
          message: 'invalid prefix',
          code: InvoicesRpcErrorCodes.prefixInvalid,
        ),
        permissionCode: InvoiceFailureCodes.permissionSettingsManagement,
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.code, InvoiceFailureCodes.validationPrefixInvalid);
    });

    test('maps persisted snapshot changes to conflicts', () {
      final customerFailure = mapper.fromPostgrest(
        PostgrestException(
          message: 'customer changed',
          code: InvoicesRpcErrorCodes.customerSnapshotChanged,
        ),
        permissionCode: FailureCodes.permissionInvoicesIssue,
      );
      final tripFailure = mapper.fromPostgrest(
        PostgrestException(
          message: 'trip changed',
          code: InvoicesRpcErrorCodes.tripSnapshotChanged,
        ),
        permissionCode: FailureCodes.permissionInvoicesIssue,
      );

      expect(
        customerFailure.code,
        FailureCodes.conflictInvoiceCustomerSnapshotChanged,
      );
      expect(tripFailure.code, FailureCodes.conflictInvoiceTripSnapshotChanged);
    });

    test('maps invoices with registered payments to cancellation conflict', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'invoice_has_payments',
          code: InvoicesRpcErrorCodes.hasPayments,
        ),
        permissionCode: FailureCodes.permissionInvoicesCancel,
      );

      expect(failure, isA<ConflictFailure>());
      expect(failure.code, InvoiceFailureCodes.conflictHasPayments);
      expect(failure.message, isNull);
    });

    test('maps PostgREST no-row responses to invoice not found', () {
      final failure = mapper.fromPostgrest(
        PostgrestException(
          message: 'JSON object requested, multiple or no rows returned',
          code: InvoicesRpcErrorCodes.noRowsReturned,
        ),
        permissionCode: FailureCodes.permissionInvoicesView,
      );

      expect(failure, isA<NotFoundFailure>());
      expect(failure.code, InvoiceFailureCodes.notFound);
      expect(failure.message, isNull);
    });

    test('sanitizes unknown persistence failures', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'secret backend details',
          code: 'XX999',
          details: 'private schema detail',
          hint: 'internal hint',
        ),
        permissionCode: FailureCodes.permissionInvoicesView,
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });

    test(
      'maps corrupt persistence format errors to generic server failure',
      () {
        final failure = mapper.fromFormatException(
          const FormatException('invalid persisted invoice data'),
        );

        expect(failure, isA<ServerFailure>());
        expect(failure.code, FailureCodes.serverError);
        expect(failure.message, isNull);
      },
    );

    test('maps unexpected exceptions without exposing internal text', () {
      final failure = mapper.fromUnexpected(StateError('secret internal text'));

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, isNull);
    });
  });
}
