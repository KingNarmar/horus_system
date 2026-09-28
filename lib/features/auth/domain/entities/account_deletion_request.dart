enum AccountDeletionStatus { pending, cancelled, finalized }

class AccountDeletionRequest {
  final String id;
  final AccountDeletionStatus status;
  final DateTime requestedAt;
  final DateTime eligibleAfter;

  const AccountDeletionRequest({
    required this.id,
    required this.status,
    required this.requestedAt,
    required this.eligibleAfter,
  });
}
