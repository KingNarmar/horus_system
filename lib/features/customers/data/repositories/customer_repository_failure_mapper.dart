import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../subscriptions/domain/failures/quota_failure_codes.dart';

final class CustomerRepositoryFailureMapper {
  const CustomerRepositoryFailureMapper();

  Failure fromPostgrest(PostgrestException error) {
    if (error.code == 'P2860' &&
        error.message == QuotaFailureCodes.customersReached) {
      return const ConflictFailure(code: QuotaFailureCodes.customersReached);
    }
    if (error.code == 'P2861' || error.code == 'P2862') {
      return const ServerFailure(code: QuotaFailureCodes.unavailable);
    }
    return const ServerFailure(code: FailureCodes.serverError);
  }

  Failure fromUnexpected(Object _) {
    return const UnexpectedFailure();
  }
}
