import '../../../../core/utils/result.dart';
import '../../domain/repositories/password_recovery_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import 'auth_repository_failure_mapper.dart';

final class PasswordRecoveryRepositoryImpl
    implements PasswordRecoveryRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final Uri _recoveryRedirectUri;

  const PasswordRecoveryRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required Uri recoveryRedirectUri,
  }) : _remoteDataSource = remoteDataSource,
       _recoveryRedirectUri = recoveryRedirectUri;

  static const _failureMapper = AuthRepositoryFailureMapper();

  @override
  Future<Result<void>> requestPasswordRecovery({required String email}) async {
    try {
      await _remoteDataSource.requestPasswordRecovery(
        email: email,
        redirectTo: _recoveryRedirectUri.toString(),
      );
      return const Success<void>(null);
    } catch (error) {
      return FailureResult(_failureMapper.fromException(error));
    }
  }
}
