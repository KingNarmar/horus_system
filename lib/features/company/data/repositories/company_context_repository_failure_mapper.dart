import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/context/current_company_provider.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../domain/failures/company_failure_codes.dart';

final class CompanyContextRepositoryFailureMapper {
  const CompanyContextRepositoryFailureMapper();

  Failure fromAuthException(AuthException _) {
    return const AuthFailure(code: CompanyFailureCodes.authRequired);
  }

  Failure fromPostgrest(PostgrestException _) {
    return const ServerFailure(code: FailureCodes.serverError);
  }

  Failure fromMissingCompanyContext(MissingCompanyContextException _) {
    return const ValidationFailure(
      code: FailureCodes.validationCompanyContextRequired,
    );
  }

  Failure fromUnexpected(Object _) {
    return const UnexpectedFailure();
  }
}
