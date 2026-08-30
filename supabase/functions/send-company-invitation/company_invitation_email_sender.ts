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

export function createCompanyInvitationEmailSender(): CompanyInvitationEmailSender {
  const endpoint = Deno.env.get('HORUS_INVITATION_EMAIL_WEBHOOK_URL')?.trim()
  const apiKey = Deno.env.get('HORUS_INVITATION_EMAIL_WEBHOOK_KEY')?.trim()
  const from = Deno.env.get('HORUS_INVITATION_EMAIL_FROM')?.trim()

  if (!endpoint || !apiKey || !from) {
    return new UnconfiguredCompanyInvitationEmailSender()
  }

  return new WebhookCompanyInvitationEmailSender(endpoint, apiKey, from)
}

class UnconfiguredCompanyInvitationEmailSender
  implements CompanyInvitationEmailSender {
  readonly isConfigured = false

  async send(_message: CompanyInvitationEmailMessage): Promise<void> {
    throw new CompanyInvitationDeliveryNotConfiguredError()
  }
}

class WebhookCompanyInvitationEmailSender
  implements CompanyInvitationEmailSender {
  readonly isConfigured = true

  constructor(
    private readonly endpoint: string,
    private readonly apiKey: string,
    private readonly from: string,
  ) {}

  async send(message: CompanyInvitationEmailMessage): Promise<void> {
    let response: Response

    try {
      response = await fetch(this.endpoint, {
        method: 'POST',
        headers: {
          'authorization': `Bearer ${this.apiKey}`,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          from: this.from,
          to: message.to,
          subject: message.subject,
          text: message.text,
          html: message.html,
        }),
      })
    } catch (_) {
      throw new CompanyInvitationDeliveryFailedError()
    }

    if (!response.ok) {
      throw new CompanyInvitationDeliveryFailedError()
    }
  }
}
