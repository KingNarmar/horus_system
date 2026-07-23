import 'package:horus_system/core/errors/failure_codes.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class RegisterParams {
  final String fullName;
  final String phone;
  final String email;
  final String password;

  const RegisterParams({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
  });
}

class RegisterUseCase implements UseCase<AuthUser, RegisterParams> {
  final AuthRepository _repository;

  const RegisterUseCase(this._repository);

  @override
  Future<Result<AuthUser>> call(RegisterParams params) {
    final fullName = params.fullName.trim();
    final phone = params.phone.trim();
    final email = params.email.trim();
    final password = params.password;

    if (fullName.isEmpty) {
      return Future.value(
        const FailureResult<AuthUser>(
          ValidationFailure(
            code: FailureCodes.authFullNameRequired,
            message: 'Full name is required.',
          ),
        ),
      );
    }

    if (phone.isEmpty) {
      return Future.value(
        const FailureResult<AuthUser>(
          ValidationFailure(
            code: FailureCodes.authPhoneRequired,
            message: 'Phone number is required.',
          ),
        ),
      );
    }

    if (email.isEmpty) {
      return Future.value(
        const FailureResult<AuthUser>(
          ValidationFailure(
            code: FailureCodes.authEmailRequired,
            message: 'Email is required.',
          ),
        ),
      );
    }

    if (password.length < 6) {
      return Future.value(
        const FailureResult<AuthUser>(
          ValidationFailure(
            code: FailureCodes.authPasswordTooShort,
            message: 'Password must be at least 6 characters.',
          ),
        ),
      );
    }

    return _repository.register(
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
    );
  }
}
