import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';

final class FleetRepositoryFailureMapper {
  const FleetRepositoryFailureMapper();

  Failure fromPostgrest(PostgrestException error) {
    return ServerFailure(
      code: error.code ?? FailureCodes.serverError,
      message: error.message,
    );
  }

  Failure fromUnexpected(Object error) {
    return UnexpectedFailure(message: error.toString());
  }
}
