import type { CompanyInvitationEmailContent } from './invitation_email_template.ts'

export type CompanyInvitationEmailMessage = CompanyInvitationEmailContent & {
  to: string
}

export interface CompanyInvitationEmailSender {
  readonly isConfigured: boolean
  send(message: CompanyInvitationEmailMessage): Promise<void>
}

export class CompanyInvitationDeliveryNotConfiguredError extends Error {
  constructor() {
    super('company_invitation_delivery_not_configured')
  }
}

export class CompanyInvitationDeliveryFailedError extends Error {
  constructor() {
    super('company_invitation_delivery_failed')
  }
}

export class UnconfiguredCompanyInvitationEmailSender
  implements CompanyInvitationEmailSender {
  readonly isConfigured = false

  async send(_message: CompanyInvitationEmailMessage): Promise<void> {
    throw new CompanyInvitationDeliveryNotConfiguredError()
  }
}
