import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/dashboard/data/constants/dashboard_db_constants.dart';
import 'package:horus_system/features/dashboard/data/repositories/dashboard_repository_failure_mapper.dart';
import 'package:horus_system/features/dashboard/domain/failures/dashboard_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('DashboardRepositoryFailureMapper', () {
    const mapper = DashboardRepositoryFailureMapper();

    test('maps auth exceptions to auth-required failure', () {
      final failure = mapper.fromAuthException(AuthException('expired'));

      expect(failure, isA<AuthFailure>());
      expect(failure.code, CompanyFailureCodes.authRequired);
      expect(failure.message, isNull);
    });

    test('maps dashboard RPC permission denial to view permission', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'permission denied',
          code: DashboardRpcErrorCodes.permissionDenied,
        ),
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, DashboardFailureCodes.permissionView);
      expect(failure.message, isNull);
    });

    test('maps direct table privilege denial to view permission', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(message: 'permission denied', code: '42501'),
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, DashboardFailureCodes.permissionView);
      expect(failure.message, isNull);
    });

    test('maps company-not-found RPC failure', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'company not found',
          code: DashboardRpcErrorCodes.companyNotFound,
        ),
      );

      expect(failure, isA<NotFoundFailure>());
      expect(failure.code, CompanyFailureCodes.notFound);
      expect(failure.message, isNull);
    });

    test('maps missing regional settings to typed conflict', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'internal database wording',
          code: DashboardRpcErrorCodes.regionalSettingsNotConfigured,
        ),
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
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });

    test('maps format failures to generic server failure', () {
      final failure = mapper.fromFormatException(
        const FormatException('invalid dashboard source'),
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
