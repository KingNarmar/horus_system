import '../../../../core/errors/failure.dart';
import '../../domain/entities/account_deletion_status.dart';

sealed class AccountDeletionState {
  const AccountDeletionState();
}

final class AccountDeletionInitial extends AccountDeletionState {
  const AccountDeletionInitial();
}

final class AccountDeletionLoading extends AccountDeletionState {
  const AccountDeletionLoading();
}

final class AccountDeletionReady extends AccountDeletionState {
  final AccountDeletionStatus status;

  const AccountDeletionReady(this.status);
}

final class AccountDeletionFailure extends AccountDeletionState {
  final Failure failure;

  const AccountDeletionFailure(this.failure);
}
