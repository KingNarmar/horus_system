import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../domain/failures/trip_failure_codes.dart';
import '../constants/trip_db_contract.dart';

final class TripRepositoryFailureMapper {
  const TripRepositoryFailureMapper();

  Failure fromPostgrest(PostgrestException error) {
    return switch (error.code) {
      TripDbErrorCodes.managementPermissionDenied => const PermissionFailure(
        code: FailureCodes.permissionTripsManagement,
      ),
      TripDbErrorCodes.statusPermissionDenied => const PermissionFailure(
        code: FailureCodes.permissionTripStatusUpdate,
      ),
      TripDbErrorCodes.notFound => const NotFoundFailure(
        code: TripFailureCodes.notFound,
      ),
      TripDbErrorCodes.temporalOrderInvalid => const ValidationFailure(
        code: FailureCodes.validationTripDeliveryBeforeLoading,
      ),
      TripDbErrorCodes.checkViolation
          when _isTemporalConstraintViolation(error) =>
        const ValidationFailure(
          code: FailureCodes.validationTripDeliveryBeforeLoading,
        ),
      _ => const ServerFailure(code: FailureCodes.serverError),
    };
  }

  Failure fromUnexpected(Object error) {
    return const UnexpectedFailure(code: FailureCodes.unexpectedError);
  }

  bool _isTemporalConstraintViolation(PostgrestException error) {
    final message = error.message;
    return message.contains(
          TripDbConstraints.scheduledDeliveryNotBeforeLoading,
        ) ||
        message.contains(TripDbConstraints.actualDeliveryNotBeforeLoading);
  }
}
