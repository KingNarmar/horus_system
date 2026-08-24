import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';

final class SubscriptionsRepositoryFailureMapper {
  const SubscriptionsRepositoryFailureMapper();

  Failure fromPostgrest(PostgrestException error) {
    return switch (error.code) {
      '42501' => const PermissionFailure(
        code: FailureCodes.permissionSubscriptionsView,
        message: 'Subscription view is not allowed.',
      ),
      _ => ServerFailure(
        code: FailureCodes.serverError,
        message: error.message,
      ),
    };
  }

  Failure fromUnexpected(Object error) {
    return UnexpectedFailure(message: error.toString());
  }
}
