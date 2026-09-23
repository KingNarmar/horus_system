import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../domain/failures/company_failure_codes.dart';

final class CompanyUsersRepositoryFailureMapper {
  const CompanyUsersRepositoryFailureMapper();

  Failure fromPostgrest(PostgrestException error) {
    return switch (error.message) {
      CompanyFailureCodes.authRequired => const AuthFailure(
        code: CompanyFailureCodes.authRequired,
      ),
      'company_users_permission_denied' => const PermissionFailure(
        code: FailureCodes.permissionCompanyUsersView,
      ),
      _ => const ServerFailure(code: FailureCodes.serverError),
    };
  }

  Failure fromUnexpected(Object _) {
    return const UnexpectedFailure();
  }
}
