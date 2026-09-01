import { BrevoCompanyInvitationEmailSender } from './brevo_company_invitation_email_sender.ts'
import {
  type CompanyInvitationEmailSender,
  UnconfiguredCompanyInvitationEmailSender,
} from './company_invitation_email_sender.ts'

type EnvironmentReader = (name: string) => string | undefined

export function createCompanyInvitationEmailSender(
  readEnvironment: EnvironmentReader = (name) => Deno.env.get(name),
): CompanyInvitationEmailSender {
  const apiKey = readEnvironment('HORUS_INVITATION_BREVO_API_KEY')?.trim()
  const fromEmail = readEnvironment('HORUS_INVITATION_EMAIL_FROM_EMAIL')?.trim()
  const fromName = readEnvironment('HORUS_INVITATION_EMAIL_FROM_NAME')?.trim()

  if (!apiKey || !fromEmail || !fromName) {
    return new UnconfiguredCompanyInvitationEmailSender()
  }

  return new BrevoCompanyInvitationEmailSender({
    apiKey,
    fromEmail,
    fromName,
  })
}
