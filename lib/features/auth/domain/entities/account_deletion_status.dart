enum AccountDeletionRequestState { none, pending }

final class AccountDeletionStatus {
  final AccountDeletionRequestState state;
  final DateTime? requestedAt;
  final DateTime? scheduledFor;

  const AccountDeletionStatus({
    required this.state,
    this.requestedAt,
    this.scheduledFor,
  });

  bool get isPending => state == AccountDeletionRequestState.pending;
}
