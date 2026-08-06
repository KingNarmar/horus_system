import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/data/constants/company_rpc_error_codes.dart';
import 'package:horus_system/features/company/data/mappers/company_regional_settings_failure_mapper.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyRegionalSettingsFailureMapper', () {
    test('maps permission denial to a domain permission failure', () {
      final failure = CompanyRegionalSettingsFailureMapper.fromPostgrest(
        PostgrestException(
          message: 'permission denied',
          code: CompanyRpcErrorCodes.settingsPermissionDenied,
        ),
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, CompanyFailureCodes.permissionSettingsManagement);
    });

    test('maps invalid timezone to a domain validation failure', () {
      final failure = CompanyRegionalSettingsFailureMapper.fromPostgrest(
        PostgrestException(
          message: 'invalid timezone',
          code: CompanyRpcErrorCodes.businessTimezoneInvalid,
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect(
        failure.code,
        CompanyFailureCodes.validationBusinessTimezoneInvalid,
      );
    });

    test('maps missing company to a domain not-found failure', () {
      final failure = CompanyRegionalSettingsFailureMapper.fromPostgrest(
        PostgrestException(
          message: 'company not found',
          code: CompanyRpcErrorCodes.companyNotFound,
        ),
      );

      expect(failure, isA<NotFoundFailure>());
      expect(failure.code, CompanyFailureCodes.notFound);
    });

    test('sanitizes unknown persistence failures', () {
      final failure = CompanyRegionalSettingsFailureMapper.fromPostgrest(
        const PostgrestException(
          message: 'secret backend details',
          code: 'XX998',
          details: 'private schema detail',
          hint: 'internal hint',
        ),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });
  });
}
