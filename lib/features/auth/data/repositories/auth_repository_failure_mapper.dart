import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';

final class AuthRepositoryFailureMapper {
  const AuthRepositoryFailureMapper();

  Failure fromAuthException(AuthException error) {
    return AuthFailure(
      code: error.statusCode ?? 'auth_error',
      message: error.message,
    );
  }

  Failure fromUnexpected(Object error) {
    return UnexpectedFailure(message: error.toString());
  }
}
