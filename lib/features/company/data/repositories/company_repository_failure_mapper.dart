import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../domain/failures/company_failure_codes.dart';

final class CompanyRepositoryFailureMapper {
  const CompanyRepositoryFailureMapper();

  Failure fromAuthException(AuthException _) {
    return const AuthFailure(code: CompanyFailureCodes.authRequired);
  }

  Failure fromPostgrest(PostgrestException _) {
    return const ServerFailure(code: FailureCodes.serverError);
  }

  Failure fromUnexpected(Object _) {
    return const UnexpectedFailure();
  }
}
