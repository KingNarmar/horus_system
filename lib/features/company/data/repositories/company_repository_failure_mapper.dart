import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../domain/failures/company_failure_codes.dart';
import '../constants/company_rpc_error_codes.dart';

final class CompanyRepositoryFailureMapper {
  const CompanyRepositoryFailureMapper();

  Failure fromAuthException(AuthException _) {
    return const AuthFailure(code: CompanyFailureCodes.authRequired);
  }

  Failure fromPostgrest(PostgrestException error) {
    return switch (error.code) {
      CompanyRpcErrorCodes.onboardingAuthRequired => const AuthFailure(
        code: CompanyFailureCodes.authRequired,
      ),
      CompanyRpcErrorCodes.onboardingCompanyNameRequired =>
        const ValidationFailure(
          code: FailureCodes.validationCompanyNameRequired,
        ),
      CompanyRpcErrorCodes.onboardingBusinessTimezoneInvalid =>
        const ValidationFailure(
          code: CompanyFailureCodes.validationBusinessTimezoneInvalid,
        ),
      _ => const ServerFailure(code: FailureCodes.serverError),
    };
  }

  Failure fromUnexpected(Object _) {
    return const UnexpectedFailure();
  }
}
