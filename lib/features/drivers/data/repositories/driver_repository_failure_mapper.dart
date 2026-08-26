import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';

final class DriverRepositoryFailureMapper {
  const DriverRepositoryFailureMapper();

  Failure fromPostgrest(PostgrestException _) {
    return const ServerFailure(code: FailureCodes.serverError);
  }

  Failure fromStorage(StorageException error) {
    final message = error.message.toLowerCase();
    final statusCode = error.statusCode;
    if (statusCode == '413' || message.contains('too large')) {
      return const ValidationFailure(
        code: FailureCodes.validationDriverImageTooLarge,
        message: 'Driver image file is too large.',
      );
    }
    if (statusCode == '415' ||
        message.contains('mime') ||
        message.contains('type')) {
      return const ValidationFailure(
        code: FailureCodes.validationDriverImageTypeUnsupported,
        message: 'Driver image file type is not supported.',
      );
    }
    return const ServerFailure(code: FailureCodes.serverError);
  }

  Failure fromUnexpected(Object _) {
    return const UnexpectedFailure();
  }
}
