import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';

final class AuthRepositoryFailureMapper {
  const AuthRepositoryFailureMapper();

  static const _invalidCredentialsCode = 'invalid_credentials';
  static const _emailNotConfirmedCode = 'email_not_confirmed';
  static const _emailExistsCode = 'email_exists';
  static const _userAlreadyExistsCode = 'user_already_exists';
  static const _weakPasswordCode = 'weak_password';
  static const _invalidEmailCode = 'email_address_invalid';
  static const _requestRateLimitCode = 'over_request_rate_limit';
  static const _emailSendRateLimitCode = 'over_email_send_rate_limit';

  Failure fromException(Object error) {
    if (error is AuthException) {
      return fromAuthException(error);
    }

    if (error is PostgrestException) {
      return fromPostgrest(error);
    }

    return fromUnexpected(error);
  }

  Failure fromAuthException(AuthException error) {
    final code = switch (error.code) {
      _invalidCredentialsCode => FailureCodes.authInvalidCredentials,
      _emailNotConfirmedCode => FailureCodes.authEmailNotConfirmed,
      _emailExistsCode => FailureCodes.authAccountAlreadyExists,
      _userAlreadyExistsCode => FailureCodes.authAccountAlreadyExists,
      _weakPasswordCode => FailureCodes.authWeakPassword,
      _invalidEmailCode => FailureCodes.authInvalidEmail,
      _requestRateLimitCode => FailureCodes.authRateLimited,
      _emailSendRateLimitCode => FailureCodes.authRateLimited,
      _ => FailureCodes.authError,
    };

    return AuthFailure(code: code);
  }

  Failure fromPostgrest(PostgrestException error) {
    return const ServerFailure(code: FailureCodes.serverError);
  }

  Failure fromUnexpected(Object error) {
    return const UnexpectedFailure(code: FailureCodes.unexpectedError);
  }
}
