import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';

final class DriverFinanceRepositoryFailureMapper {
  const DriverFinanceRepositoryFailureMapper();

  Failure fromMovementPostgrest(PostgrestException error) {
    return _serverFailure(error);
  }

  Failure fromBalancePostgrest(PostgrestException error) {
    if (error.code == '42501') {
      return const PermissionFailure(
        code: FailureCodes.permissionDriverFinanceView,
        message: 'Driver finance access is not allowed.',
      );
    }
    return _serverFailure(error);
  }

  Failure fromUnexpected(Object error) {
    return UnexpectedFailure(message: error.toString());
  }

  Failure _serverFailure(PostgrestException error) {
    return ServerFailure(
      code: error.code ?? FailureCodes.serverError,
      message: error.message,
    );
  }
}
