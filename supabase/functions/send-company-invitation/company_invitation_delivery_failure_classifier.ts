import {
  CompanyInvitationDeliveryFailedError,
  CompanyInvitationDeliveryNotConfiguredError,
  CompanyInvitationDeliveryOutcomeUnknownError,
} from './company_invitation_email_sender.ts'

/** Unknown provider outcomes must never invalidate a possibly delivered token. */
export function classifyInvitationSendError(error: unknown): string {
  if (error instanceof CompanyInvitationDeliveryNotConfiguredError) {
    return 'company_invitation_delivery_not_configured'
  }
  if (error instanceof CompanyInvitationDeliveryOutcomeUnknownError) {
    return 'company_invitation_delivery_confirmation_unknown'
  }
  if (error instanceof CompanyInvitationDeliveryFailedError) {
    return 'company_invitation_delivery_failed'
  }
  return 'company_invitation_delivery_confirmation_unknown'
}
