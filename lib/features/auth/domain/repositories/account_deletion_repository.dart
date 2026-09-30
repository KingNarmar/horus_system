import '../../../../core/utils/result.dart';
import '../entities/account_deletion_status.dart';

abstract interface class AccountDeletionRepository {
  Future<Result<AccountDeletionStatus>> getStatus();

  Future<Result<AccountDeletionStatus>> requestDeletion();

  Future<Result<AccountDeletionStatus>> cancelDeletion();
}
