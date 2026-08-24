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
        message: 'A payment method with this name already exists.',
      ),
      'PGRST116' => const NotFoundFailure(
        code: FailureCodes.paymentMethodNotFound,
        message: 'Payment method was not found.',
      ),
      '42501' => PermissionFailure(
        code: permissionCode,
        message: 'Payment method access is not allowed.',
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
