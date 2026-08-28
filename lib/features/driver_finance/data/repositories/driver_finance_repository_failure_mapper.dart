import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';

final class DriverFinanceRepositoryFailureMapper {
  const DriverFinanceRepositoryFailureMapper();

  Failure fromMovementPostgrest(PostgrestException error) {
    return const ServerFailure(code: FailureCodes.serverError);
  }

  Failure fromBalancePostgrest(PostgrestException error) {
    if (error.code == '42501') {
      return const PermissionFailure(
        code: FailureCodes.permissionDriverFinanceView,
      );
    }
    return const ServerFailure(code: FailureCodes.serverError);
  }

  Failure fromUnexpected(Object error) {
    return const UnexpectedFailure(code: FailureCodes.unexpectedError);
  }
}
