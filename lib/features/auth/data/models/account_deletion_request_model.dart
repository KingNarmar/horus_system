class AccountDeletionRequestModel {
  final String id;
  final String status;
  final DateTime requestedAt;
  final DateTime eligibleAfter;

  const AccountDeletionRequestModel({
    required this.id,
    required this.status,
    required this.requestedAt,
    required this.eligibleAfter,
  });
}
