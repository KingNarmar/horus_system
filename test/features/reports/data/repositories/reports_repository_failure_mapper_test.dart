import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/reports/data/constants/reports_db_constants.dart';
import 'package:horus_system/features/reports/data/repositories/reports_repository_failure_mapper.dart';
import 'package:horus_system/features/reports/domain/failures/reports_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('ReportsRepositoryFailureMapper', () {
    const mapper = ReportsRepositoryFailureMapper();

    test('maps auth exceptions to auth-required failure', () {
      final failure = mapper.fromAuthException(AuthException('expired'));

      expect(failure, isA<AuthFailure>());
      expect(failure.code, CompanyFailureCodes.authRequired);
      expect(failure.message, isNull);
    });

    test('maps report permission using supplied failure code', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'permission denied',
          code: ReportsRpcErrorCodes.permissionDenied,
        ),
        permissionFailureCode: ReportsFailureCodes.permissionFinancialView,
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, ReportsFailureCodes.permissionFinancialView);
    });

    test('maps direct table privilege denial using supplied failure code', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(message: 'permission denied', code: '42501'),
        permissionFailureCode: ReportsFailureCodes.permissionOperationalView,
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, ReportsFailureCodes.permissionOperationalView);
    });

    test('maps invalid date range to typed validation failure', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'invalid range',
          code: ReportsRpcErrorCodes.invalidDateRange,
        ),
        permissionFailureCode: ReportsFailureCodes.permissionFinancialView,
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.code, ReportsFailureCodes.validationDateRange);
    });

    test('maps missing company to company not-found failure', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'company missing',
          code: ReportsRpcErrorCodes.companyNotFound,
        ),
        permissionFailureCode: ReportsFailureCodes.permissionFinancialView,
      );

      expect(failure, isA<NotFoundFailure>());
      expect(failure.code, CompanyFailureCodes.notFound);
    });

    test('maps regional settings failure without exposing DB text', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'internal database wording',
          code: ReportsRpcErrorCodes.regionalSettingsNotConfigured,
        ),
        permissionFailureCode: ReportsFailureCodes.permissionFinancialView,
      );

      expect(failure, isA<ConflictFailure>());
      expect(
        failure.code,
        CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
      );
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
        permissionFailureCode: ReportsFailureCodes.permissionFinancialView,
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });

    test('maps corrupt source format errors to generic server failure', () {
      final failure = mapper.fromFormatException(
        const FormatException('invalid report source'),
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
