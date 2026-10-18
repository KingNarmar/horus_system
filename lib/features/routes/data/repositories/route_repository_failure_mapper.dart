import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../domain/failures/route_failure_codes.dart';
import '../constants/route_db_contract.dart';

final class RouteRepositoryFailureMapper {
  const RouteRepositoryFailureMapper();

  Failure fromPostgrest(PostgrestException error) {
    if (error.code == RouteDbErrorCodes.financialTermsPermissionDenied) {
      return const PermissionFailure(
        code: RouteFailureCodes.financialTermsPermissionDenied,
      );
    }
    return const ServerFailure(code: FailureCodes.serverError);
  }

  Failure fromUnexpected(Object error) {
    return const UnexpectedFailure(code: FailureCodes.unexpectedError);
  }
}
