import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/failures/dashboard_failure_codes.dart';
import '../constants/dashboard_db_constants.dart';

final class DashboardRepositoryFailureMapper {
  const DashboardRepositoryFailureMapper();

  Failure fromAuthException(AuthException _) {
    return const AuthFailure(code: CompanyFailureCodes.authRequired);
  }

  Failure fromPostgrest(PostgrestException error) {
    return switch (error.code) {
      DashboardRpcErrorCodes.permissionDenied || '42501' =>
        const PermissionFailure(code: DashboardFailureCodes.permissionView),
      DashboardRpcErrorCodes.companyNotFound => const NotFoundFailure(
        code: CompanyFailureCodes.notFound,
      ),
      DashboardRpcErrorCodes.regionalSettingsNotConfigured =>
        const ConflictFailure(
          code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        ),
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
