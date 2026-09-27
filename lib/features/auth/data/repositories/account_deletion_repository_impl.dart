import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/account_deletion_status.dart';
import '../../domain/repositories/account_deletion_repository.dart';
import '../datasources/account_deletion_remote_data_source.dart';

final class AccountDeletionRepositoryImpl implements AccountDeletionRepository {
  final AccountDeletionRemoteDataSource _remoteDataSource;

  const AccountDeletionRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<AccountDeletionStatus>> getStatus() {
    return _guard(() async {
      final model = await _remoteDataSource.getStatus();
      return model?.toEntity() ??
          const AccountDeletionStatus(state: AccountDeletionState.none);
    });
  }

  @override
  Future<Result<AccountDeletionStatus>> requestDeletion() {
    return _guard(() async {
      return (await _remoteDataSource.requestDeletion()).toEntity();
    });
  }

  @override
  Future<Result<AccountDeletionStatus>> cancelDeletion() {
    return _guard(() async {
      await _remoteDataSource.cancelDeletion();
      return const AccountDeletionStatus(state: AccountDeletionState.none);
    });
  }

  Future<Result<AccountDeletionStatus>> _guard(
    Future<AccountDeletionStatus> Function() action,
  ) async {
    try {
      return Success(await action());
    } on PostgrestException catch (error) {
      if (error.code == 'P1961' ||
          error.message == 'account_deletion_sole_owner') {
        return const FailureResult(
          ConflictFailure(code: FailureCodes.accountDeletionSoleOwner),
        );
      }
      return const FailureResult(
        ServerFailure(code: FailureCodes.serverError),
      );
    } catch (_) {
      return const FailureResult(
        UnexpectedFailure(code: FailureCodes.unexpectedError),
      );
    }
  }
}
