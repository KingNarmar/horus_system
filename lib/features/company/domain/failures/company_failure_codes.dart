abstract final class CompanyFailureCodes {
  static const authRequired = 'company_auth_required';
  static const permissionSettingsManagement =
      'permission_company_settings_management';
  static const validationBaseCurrencyInvalid =
      'validation_company_base_currency_invalid';
  static const validationBaseCurrencyFractionDigitsInvalid =
      'validation_company_base_currency_fraction_digits_invalid';
  static const validationBusinessTimezoneRequired =
      'validation_company_business_timezone_required';
  static const validationBusinessTimezoneInvalid =
      'validation_company_business_timezone_invalid';
  static const validationInvitationIdRequired =
      'validation_company_invitation_id_required';
  static const validationInvitationTokenRequired =
      'validation_company_invitation_token_required';
  static const validationMembershipIdRequired =
      'validation_company_membership_id_required';
  static const conflictBaseCurrencyLocked =
      'conflict_company_base_currency_locked';
  static const conflictRegionalSettingsNotConfigured =
      'conflict_company_regional_settings_not_configured';
  static const companyNotAvailable = 'company_not_available';
  static const notFound = 'company_not_found';

  static const invitationInvalid = 'company_invitation_invalid';
  static const invitationEmailInvalid = 'company_invitation_email_invalid';
  static const invitationExpired = 'company_invitation_expired';
  static const invitationRevoked = 'company_invitation_revoked';
  static const invitationAlreadyAccepted =
      'company_invitation_already_accepted';
  static const invitationAlreadyPending = 'company_invitation_already_pending';
  static const invitationEmailMismatch = 'company_invitation_email_mismatch';
  static const invitationEmailNotVerified =
      'company_invitation_email_not_verified';
  static const invitationRoleNotAllowed =
      'company_invitation_role_not_allowed';
  static const invitationPermissionDenied =
      'company_invitation_permission_denied';
  static const invitationDeliveryFailed =
      'company_invitation_delivery_failed';
  static const invitationDeliveryConfirmationUnknown =
      'company_invitation_delivery_confirmation_unknown';
  static const invitationDeliveryNotConfigured =
      'company_invitation_delivery_not_configured';

  static const memberAlreadyActive = 'company_member_already_active';
  static const memberInactive = 'company_member_inactive';
  static const memberNotFound = 'company_member_not_found';
  static const memberRoleChangeNotAllowed =
      'company_member_role_change_not_allowed';
  static const memberStatusChangeNotAllowed =
      'company_member_status_change_not_allowed';
  static const ownershipCommandRequired =
      'company_ownership_command_required';
  static const ownershipTransferNotAllowed =
      'company_ownership_transfer_not_allowed';
  static const lastOwnerRequired = 'company_last_owner_required';
}
