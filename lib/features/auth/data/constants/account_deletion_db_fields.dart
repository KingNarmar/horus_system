abstract final class AccountDeletionDbFields {
  const AccountDeletionDbFields._();

  static const String status = 'status';
  static const String requestedAt = 'requested_at';
  static const String scheduledFor = 'scheduled_for';

  static const String getStatusRpc = 'get_my_account_deletion_status';
  static const String requestRpc = 'request_my_account_deletion';
  static const String cancelRpc = 'cancel_my_account_deletion';
}
