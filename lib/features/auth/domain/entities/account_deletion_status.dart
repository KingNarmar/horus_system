enum AccountDeletionState { none, pending }

final class AccountDeletionStatus {
  final AccountDeletionState state;
  final DateTime? requestedAt;
  final DateTime? scheduledFor;

  const AccountDeletionStatus({
    required this.state,
    this.requestedAt,
    this.scheduledFor,
  });

  bool get isPending => state == AccountDeletionState.pending;
}
