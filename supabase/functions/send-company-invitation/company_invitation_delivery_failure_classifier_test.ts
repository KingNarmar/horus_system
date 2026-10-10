import { classifyInvitationSendError } from './company_invitation_delivery_failure_classifier.ts'
import {
  CompanyInvitationDeliveryFailedError,
  CompanyInvitationDeliveryNotConfiguredError,
  CompanyInvitationDeliveryOutcomeUnknownError,
} from './company_invitation_email_sender.ts'

Deno.test('only explicit provider rejection permits resend abort', () => {
  const cases: [unknown, string][] = [
    [new CompanyInvitationDeliveryFailedError(), 'company_invitation_delivery_failed'],
    [new CompanyInvitationDeliveryNotConfiguredError(), 'company_invitation_delivery_not_configured'],
    [new CompanyInvitationDeliveryOutcomeUnknownError(), 'company_invitation_delivery_confirmation_unknown'],
    [new Error('unexpected response'), 'company_invitation_delivery_confirmation_unknown'],
    [new TypeError('network problem'), 'company_invitation_delivery_confirmation_unknown'],
    [null, 'company_invitation_delivery_confirmation_unknown'],
  ]
  for (const [error, expected] of cases) {
    if (classifyInvitationSendError(error) !== expected) {
      throw new Error('Incorrect safe delivery failure classification')
    }
  }
})
