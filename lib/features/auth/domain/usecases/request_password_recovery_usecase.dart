import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/validators/app_validators.dart';
import '../repositories/password_recovery_repository.dart';

final class RequestPasswordRecoveryParams {
  final String email;

  const RequestPasswordRecoveryParams({required this.email});
}

final class RequestPasswordRecoveryUseCase
    implements UseCase<void, RequestPasswordRecoveryParams> {
  final PasswordRecoveryRepository _repository;

  const RequestPasswordRecoveryUseCase(this._repository);

  @override
  Future<Result<void>> call(RequestPasswordRecoveryParams params) {
    final email = params.email.trim();

    if (email.isEmpty) {
      return Future.value(
        const FailureResult<void>(
          ValidationFailure(
            code: FailureCodes.authEmailRequired,
            message: 'Email is required.',
          ),
        ),
      );
    }

    if (!AppValidators.hasValidEmail(email)) {
      return Future.value(
        const FailureResult<void>(
          ValidationFailure(
            code: FailureCodes.authInvalidEmail,
            message: 'Email address is invalid.',
          ),
        ),
      );
    }

    return _repository.requestPasswordRecovery(email: email);
  }
}
