import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../domain/failures/company_failure_codes.dart';
import '../constants/company_rpc_error_codes.dart';

final class CompanyTimezoneRepositoryFailureMapper {
  const CompanyTimezoneRepositoryFailureMapper();

  Failure fromAuthException(AuthException _) {
    return const AuthFailure(code: CompanyFailureCodes.authRequired);
  }

  Failure fromPostgrest(PostgrestException error) {
    return switch (error.code) {
      CompanyRpcErrorCodes.timezoneCatalogAuthRequired =>
        const AuthFailure(code: CompanyFailureCodes.authRequired),
      CompanyRpcErrorCodes.settingsPermissionDenied || '42501' =>
        const PermissionFailure(
          code: CompanyFailureCodes.permissionSettingsManagement,
        ),
      CompanyRpcErrorCodes.businessTimezoneInvalid => const ValidationFailure(
        code: CompanyFailureCodes.validationBusinessTimezoneInvalid,
      ),
      CompanyRpcErrorCodes.companyNotFound =>
        const NotFoundFailure(code: CompanyFailureCodes.notFound),
      _ => const ServerFailure(code: FailureCodes.serverError),
    };
  }

  Failure fromFormatException(FormatException _) {
    return const ServerFailure(code: FailureCodes.serverError);
  }

  Failure fromUnexpected(Object _) {
    return const UnexpectedFailure();
  }
}
