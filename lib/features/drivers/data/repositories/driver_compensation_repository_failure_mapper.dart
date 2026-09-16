import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/failures/driver_compensation_failure_codes.dart';

final class DriverCompensationRepositoryFailureMapper {
  const DriverCompensationRepositoryFailureMapper();

  Failure fromPostgrest(
    PostgrestException error, {
    required String permissionCode,
  }) {
    if (error.code == '23P01') {
      return const ConflictFailure(
        code: DriverCompensationFailureCodes.conflictOverlap,
      );
    }
    if (error.code == '23503') {
      return const NotFoundFailure(
        code: DriverCompensationFailureCodes.notFoundDriver,
      );
    }
    if (error.code == 'PGRST116') {
      return const NotFoundFailure(
        code: DriverCompensationFailureCodes.notFoundRevision,
      );
    }
    if (error.code == '42501') {
      return PermissionFailure(code: permissionCode);
    }
    if (error.code == '23514') {
      final message = error.message;
      if (message.contains('effective_to_immutable')) {
        return const ConflictFailure(
          code:
              DriverCompensationFailureCodes.conflictRevisionAlreadyEnded,
        );
      }
      if (message.contains('document_immutable')) {
        return const ConflictFailure(
          code:
              DriverCompensationFailureCodes.conflictDocumentAlreadyAttached,
        );
      }
      return const ValidationFailure(
        code:
            DriverCompensationFailureCodes.validationEffectivePeriodInvalid,
      );
    }

    return const ServerFailure(
      code: DriverCompensationFailureCodes.serverError,
    );
  }

  Failure fromUnexpected(Object _) {
    return const UnexpectedFailure(
      code: DriverCompensationFailureCodes.unexpectedError,
    );
  }
}
