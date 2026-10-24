import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../domain/failures/driver_settlement_failure_codes.dart';

final class DriverSettlementRepositoryFailureMapper {
  const DriverSettlementRepositoryFailureMapper();

  Failure fromPostgrest(PostgrestException error) {
    if (error.code == 'P2813') {
      return const PermissionFailure(
        code: FailureCodes.permissionDriverSettlementsManagement,
      );
    }
    if (error.code == 'P2814') {
      return const ValidationFailure(
        code: DriverSettlementFailureCodes.validationDraftPayloadInvalid,
      );
    }
    if (error.code == 'P2815') {
      return const ConflictFailure(
        code: DriverSettlementFailureCodes.conflictSourceSnapshotChanged,
      );
    }
    if (error.code == 'P2816') {
      return const ConflictFailure(
        code: DriverSettlementFailureCodes.conflictCompensationChanged,
      );
    }
    if (error.code == 'P2817') {
      return const ValidationFailure(
        code: DriverSettlementFailureCodes.validationExactMoneyMismatch,
      );
    }
    if (error.code == 'P2819') {
      return const ConflictFailure(
        code: DriverSettlementFailureCodes.conflictPeriodExists,
      );
    }
    if (error.code == 'P2818') {
      return const ValidationFailure(
        code: DriverSettlementFailureCodes.validationFinancialTotalsMismatch,
      );
    }
    if (error.code == 'P2812') {
      return const ConflictFailure(
        code: DriverSettlementFailureCodes.conflictExpenseSourceInvalid,
      );
    }
    return const ServerFailure(code: FailureCodes.serverError);
  }

  Failure fromUnexpected(Object error) {
    return const UnexpectedFailure(code: FailureCodes.unexpectedError);
  }
}
