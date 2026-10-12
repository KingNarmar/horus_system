import { signInvitationConfirmation } from './company_invitation_confirmation_proof.ts'

const example = {
  secret: 'test-only-secret-with-minimum-entropy-000000000000',
  companyId: '11111111-1111-4111-8111-111111111111',
  invitationId: '22222222-2222-4222-8222-222222222222',
  deliveryAttemptId: '33333333-3333-4333-8333-333333333333',
} as const

Deno.test('computes deterministic PostgreSQL-compatible HMAC proof', async () => {
  const actual = await signInvitationConfirmation({ ...example, action: 'confirm' })
  const expected = '\\x6025bf6cbecea7e41a76c832aa0f3753ba1b03a92a5d456178f3efdcccb95447'
  if (actual !== expected) throw new Error('Confirmation proof did not match the expected HMAC')
})

Deno.test('scopes proof to the requested action and company', async () => {
  const confirm = await signInvitationConfirmation({ ...example, action: 'confirm' })
  const abort = await signInvitationConfirmation({ ...example, action: 'abort' })
  const anotherCompany = await signInvitationConfirmation({
    ...example,
    companyId: '44444444-4444-4444-8444-444444444444',
    action: 'confirm',
  })
  if (confirm === abort || confirm === anotherCompany) {
    throw new Error('Proof must bind company, invitation and action')
  }
})
