import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });
}

class LoginUseCase implements UseCase<AuthUser, LoginParams> {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  @override
  Future<Result<AuthUser>> call(LoginParams params) {
    final email = params.email.trim();
    final password = params.password;

    if (email.isEmpty) {
      return Future.value(
        const FailureResult<AuthUser>(
          ValidationFailure(message: 'Email is required.'),
        ),
      );
    }

    if (password.isEmpty) {
      return Future.value(
        const FailureResult<AuthUser>(
          ValidationFailure(message: 'Password is required.'),
        ),
      );
    }

    return _repository.login(
      email: email,
      password: password,
    );
  }
}
