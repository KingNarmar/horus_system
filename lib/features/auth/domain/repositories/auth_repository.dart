import '../../../../core/utils/result.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  });

  Future<Result<void>> logout();

  Future<Result<AuthUser?>> getCurrentUser();
}
