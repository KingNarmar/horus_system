import {
  CompanyInvitationDeliveryFailedError,
  type CompanyInvitationEmailMessage,
  type CompanyInvitationEmailSender,
} from './company_invitation_email_sender.ts'

const brevoTransactionalEmailEndpoint = 'https://api.brevo.com/v3/smtp/email'

type BrevoCompanyInvitationEmailSenderConfig = {
  apiKey: string
  fromEmail: string
  fromName: string
}

type FetchClient = typeof fetch
type DeliveryStatusLogger = (status: number) => void

export class BrevoCompanyInvitationEmailSender
  implements CompanyInvitationEmailSender {
  readonly isConfigured = true

  constructor(
    private readonly config: BrevoCompanyInvitationEmailSenderConfig,
    private readonly fetchClient: FetchClient = fetch,
    private readonly deliveryStatusLogger: DeliveryStatusLogger = logDeliveryStatus,
  ) {}

  async send(message: CompanyInvitationEmailMessage): Promise<void> {
    let response: Response

    try {
      response = await this.fetchClient(brevoTransactionalEmailEndpoint, {
        method: 'POST',
        headers: {
          'accept': 'application/json',
          'api-key': this.config.apiKey,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          sender: {
            email: this.config.fromEmail,
            name: this.config.fromName,
          },
          to: [
            {
              email: message.to,
            },
          ],
          subject: message.subject,
          htmlContent: message.html,
        }),
      })
    } catch {
      throw new CompanyInvitationDeliveryFailedError()
    }

    if (!response.ok) {
      this.deliveryStatusLogger(response.status)
      throw new CompanyInvitationDeliveryFailedError()
    }
  }
}

function logDeliveryStatus(status: number): void {
  console.error(`Brevo invitation delivery failed with status ${status}`)
}
