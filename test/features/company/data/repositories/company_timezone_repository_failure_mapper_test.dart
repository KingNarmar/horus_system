import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/features/company/data/constants/company_rpc_error_codes.dart';
import 'package:horus_system/features/company/data/repositories/company_timezone_repository_failure_mapper.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyTimezoneRepositoryFailureMapper', () {
    const mapper = CompanyTimezoneRepositoryFailureMapper();

    test('maps timezone catalog auth rejection without backend text', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'company_timezone_auth_required',
          code: CompanyRpcErrorCodes.timezoneCatalogAuthRequired,
          details: 'private database details',
          hint: 'internal database hint',
        ),
      );

      expect(failure, isA<AuthFailure>());
      expect(failure.code, CompanyFailureCodes.authRequired);
      expect(failure.message, isNull);
    });

    test('maps settings permission rejection to typed failure', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'company_settings_permission_denied',
          code: CompanyRpcErrorCodes.settingsPermissionDenied,
          details: 'private database details',
          hint: 'internal database hint',
        ),
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, CompanyFailureCodes.permissionSettingsManagement);
      expect(failure.message, isNull);
    });

    test('maps invalid timezone rejection to typed validation failure', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'company_business_timezone_invalid',
          code: CompanyRpcErrorCodes.businessTimezoneInvalid,
          details: 'private database details',
          hint: 'internal database hint',
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect(
        failure.code,
        CompanyFailureCodes.validationBusinessTimezoneInvalid,
      );
      expect(failure.message, isNull);
    });

    test('maps company not found rejection to typed not-found failure', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'company_not_found',
          code: CompanyRpcErrorCodes.companyNotFound,
          details: 'private database details',
          hint: 'internal database hint',
        ),
      );

      expect(failure, isA<NotFoundFailure>());
      expect(failure.code, CompanyFailureCodes.notFound);
      expect(failure.message, isNull);
    });
  });
}
