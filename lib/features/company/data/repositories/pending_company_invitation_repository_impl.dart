import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/repositories/pending_company_invitation_repository.dart';
import '../datasources/pending_company_invitation_local_data_source.dart';

class PendingCompanyInvitationRepositoryImpl
    implements PendingCompanyInvitationRepository {
  final PendingCompanyInvitationLocalDataSource _localDataSource;

  const PendingCompanyInvitationRepositoryImpl({
    required PendingCompanyInvitationLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<Result<void>> storeToken(String token) {
    return _guardVoid(() => _localDataSource.saveToken(token));
  }

  @override
  Future<Result<String?>> getToken() {
    return _guard(() => _localDataSource.readToken());
  }

  @override
  Future<Result<void>> clearToken() {
    return _guardVoid(_localDataSource.clearToken);
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success<T>(await action());
    } catch (_) {
      return const FailureResult(UnexpectedFailure());
    }
  }

  Future<Result<void>> _guardVoid(Future<void> Function() action) async {
    try {
      await action();
      return const Success<void>(null);
    } catch (_) {
      return const FailureResult(UnexpectedFailure());
    }
  }
}
