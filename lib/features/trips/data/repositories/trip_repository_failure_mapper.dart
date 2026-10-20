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
      TripDbErrorCodes.financialTermsPermissionDenied =>
        const PermissionFailure(
          code: TripFailureCodes.financialTermsPermissionDenied,
        ),
      TripDbErrorCodes.pricedQuantityRequiresFinance => const ConflictFailure(
        code: TripFailureCodes.pricedQuantityRequiresFinance,
      ),
      TripDbErrorCodes.financeSnapshotStale => const ConflictFailure(
        code: TripFailureCodes.staleFinancialSnapshot,
      ),
      TripDbErrorCodes.financeRateInvalid => const ValidationFailure(
        code: FailureCodes.validationTripFreightRateInvalid,
      ),
      TripDbErrorCodes.invoiceFinancialTermsLocked => const ConflictFailure(
        code: TripFailureCodes.invoicedFinancialTermsLocked,
      ),
      TripDbErrorCodes.financeQuantityRequired => const ConflictFailure(
        code: TripFailureCodes.pricingRequiresQuantity,
      ),
      TripDbErrorCodes.readPermissionDenied => const PermissionFailure(
        code: FailureCodes.permissionTripsView,
      ),
      TripDbErrorCodes.statusPermissionDenied => const PermissionFailure(
        code: FailureCodes.permissionTripStatusUpdate,
      ),
      TripDbErrorCodes.notFound => const NotFoundFailure(
        code: TripFailureCodes.notFound,
      ),
      TripDbErrorCodes.concurrentModification => const ConflictFailure(
        code: TripFailureCodes.concurrentModification,
      ),
      TripDbErrorCodes.temporalOrderInvalid => const ValidationFailure(
        code: FailureCodes.validationTripDeliveryBeforeLoading,
      ),
      TripDbErrorCodes.evidenceRequired => const ConflictFailure(
        code: TripFailureCodes.conflictStatusEvidenceRequired,
      ),
      TripDbErrorCodes.statusTransitionInvalid => const ValidationFailure(
        code: FailureCodes.validationTripStatusTransitionInvalid,
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
