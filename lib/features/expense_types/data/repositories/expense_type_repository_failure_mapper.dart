import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';

final class ExpenseTypeRepositoryFailureMapper {
  const ExpenseTypeRepositoryFailureMapper();

  Failure fromPostgrest(
    PostgrestException error, {
    required String permissionCode,
  }) {
    return switch (error.code) {
      '23505' => const ConflictFailure(
        code: FailureCodes.conflictExpenseTypeDuplicateName,
      ),
      'PGRST116' => const NotFoundFailure(
        code: FailureCodes.expenseTypeNotFound,
      ),
      '42501' => PermissionFailure(code: permissionCode),
      _ => const ServerFailure(code: FailureCodes.serverError),
    };
  }

  Failure fromUnexpected(Object _) {
    return const UnexpectedFailure(code: FailureCodes.unexpectedError);
  }
}
