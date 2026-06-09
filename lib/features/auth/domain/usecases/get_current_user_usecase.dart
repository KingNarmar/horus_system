import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase implements UseCase<AuthUser?, NoParams> {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  @override
  Future<Result<AuthUser?>> call(NoParams params) {
    return _repository.getCurrentUser();
  }
}
