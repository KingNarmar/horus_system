import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/failures/expense_ledger_failure_codes.dart';

final class ExpenseLedgerRepositoryFailureMapper {
  const ExpenseLedgerRepositoryFailureMapper();

  Failure fromPostgrest(PostgrestException error) {
    return switch (error.code) {
      'P2801' || '42501' => const PermissionFailure(
        code: ExpenseLedgerFailureCodes.permissionManage,
      ),
      'P2802' || '23503' => const ValidationFailure(
        code: ExpenseLedgerFailureCodes.validationAttributionInvalid,
      ),
      'P2803' => const ValidationFailure(
        code: ExpenseLedgerFailureCodes.expenseTypeUnavailable,
      ),
      'P2804' => const ValidationFailure(
        code: ExpenseLedgerFailureCodes.financialConfigurationRequired,
      ),
      'P2805' => const ValidationFailure(
        code: ExpenseLedgerFailureCodes.currencyMismatch,
      ),
      'P2806' => const NotFoundFailure(
        code: ExpenseLedgerFailureCodes.notFound,
      ),
      'P2807' => const ConflictFailure(
        code: ExpenseLedgerFailureCodes.conflictAlreadyVoided,
      ),
      'P2808' => const ValidationFailure(
        code: ExpenseLedgerFailureCodes.validationAmountInvalid,
      ),
      'P2809' => const ValidationFailure(
        code: ExpenseLedgerFailureCodes.validationFundingSourceInvalid,
      ),
      _ => const ServerFailure(code: ExpenseLedgerFailureCodes.serverError),
    };
  }

  Failure fromUnexpected(Object _) {
    return const UnexpectedFailure(
      code: ExpenseLedgerFailureCodes.unexpectedError,
    );
  }
}
