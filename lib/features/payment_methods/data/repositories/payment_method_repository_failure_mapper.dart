import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';

final class PaymentMethodRepositoryFailureMapper {
  const PaymentMethodRepositoryFailureMapper();

  Failure fromPostgrest(
    PostgrestException error, {
    required String permissionCode,
  }) {
    return switch (error.code) {
      '23505' => const ConflictFailure(
        code: FailureCodes.conflictPaymentMethodDuplicateName,
      ),
      'PGRST116' => const NotFoundFailure(
        code: FailureCodes.paymentMethodNotFound,
      ),
      '42501' => PermissionFailure(code: permissionCode),
      _ => const ServerFailure(code: FailureCodes.serverError),
    };
  }

  Failure fromUnexpected(Object _) {
    return const UnexpectedFailure(code: FailureCodes.unexpectedError);
  }
}
