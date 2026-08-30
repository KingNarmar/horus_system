abstract final class CompanyInvitationRpc {
  static const list = 'list_company_invitations';
  static const prepare = 'prepare_company_invitation';
  static const prepareResend = 'prepare_company_invitation_resend';
  static const confirmDelivery = 'confirm_company_invitation_delivery';
  static const revoke = 'revoke_company_invitation';
  static const preview = 'get_company_invitation_preview';
  static const accept = 'accept_company_invitation';

  static const companyIdParam = 'p_company_id';
  static const emailParam = 'p_email';
  static const roleParam = 'p_role';
  static const tokenHashParam = 'p_token_hash';
  static const invitationIdParam = 'p_invitation_id';
  static const deliveryAttemptIdParam = 'p_delivery_attempt_id';

  static const invitationId = 'invitation_id';
  static const companyId = 'company_id';
  static const emailNormalized = 'email_normalized';
  static const invitationRole = 'invitation_role';
  static const effectiveStatus = 'effective_status';
  static const invitationStatus = 'invitation_status';
  static const expiresAt = 'expires_at';
  static const deliveryAttemptId = 'delivery_attempt_id';
  static const lastSentAt = 'last_sent_at';
  static const sendCount = 'send_count';
  static const createdAt = 'created_at';
  static const acceptedAt = 'accepted_at';
  static const revokedAt = 'revoked_at';
  static const companyName = 'company_name';
  static const membershipId = 'membership_id';
  static const membershipRole = 'membership_role';
}

abstract final class CompanyMembershipRpc {
  static const changeRole = 'change_company_member_role';
  static const deactivate = 'deactivate_company_member';
  static const reactivate = 'reactivate_company_member';
  static const grantOwnership = 'grant_company_ownership';
  static const transferOwnership = 'transfer_company_ownership';

  static const companyIdParam = 'p_company_id';
  static const membershipIdParam = 'p_membership_id';
  static const newRoleParam = 'p_new_role';
  static const targetMembershipIdParam = 'p_target_membership_id';
  static const sourceNewRoleParam = 'p_source_new_role';
}
