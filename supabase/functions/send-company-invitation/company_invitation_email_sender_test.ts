import { BrevoCompanyInvitationEmailSender } from './brevo_company_invitation_email_sender.ts'
import {
  CompanyInvitationDeliveryFailedError,
  CompanyInvitationDeliveryNotConfiguredError,
} from './company_invitation_email_sender.ts'
import { createCompanyInvitationEmailSender } from './company_invitation_email_sender_factory.ts'

Deno.test('creates unconfigured sender when Brevo configuration is incomplete', async () => {
  const values = new Map<string, string>([
    ['HORUS_INVITATION_BREVO_API_KEY', 'test-key'],
    ['HORUS_INVITATION_EMAIL_FROM_EMAIL', 'horus@example.com'],
  ])
  const sender = createCompanyInvitationEmailSender((name) => values.get(name))

  assert(!sender.isConfigured, 'Expected incomplete provider config to fail closed')
  await assertRejects(
    () => sender.send(testMessage()),
    CompanyInvitationDeliveryNotConfiguredError,
  )
})

Deno.test('creates Brevo sender when all required configuration is present', () => {
  const values = new Map<string, string>([
    ['HORUS_INVITATION_BREVO_API_KEY', ' test-key '],
    ['HORUS_INVITATION_EMAIL_FROM_EMAIL', ' horus@example.com '],
    ['HORUS_INVITATION_EMAIL_FROM_NAME', ' H.O.R.U.S System '],
  ])
  const sender = createCompanyInvitationEmailSender((name) => values.get(name))

  assert(sender.isConfigured, 'Expected complete provider config')
  assert(
    sender instanceof BrevoCompanyInvitationEmailSender,
    'Expected Brevo adapter composition',
  )
})

Deno.test('maps invitation email to Brevo transactional API contract', async () => {
  let capturedUrl = ''
  let capturedInit: RequestInit | undefined
  const fetchClient: typeof fetch = async (input, init) => {
    capturedUrl = String(input)
    capturedInit = init
    return new Response(JSON.stringify({ messageId: 'message-id' }), {
      status: 201,
    })
  }
  const sender = new BrevoCompanyInvitationEmailSender(
    {
      apiKey: 'secret-api-key',
      fromEmail: 'horus@example.com',
      fromName: 'H.O.R.U.S System',
    },
    fetchClient,
  )

  await sender.send(testMessage())

  assert(
    capturedUrl === 'https://api.brevo.com/v3/smtp/email',
    'Expected Brevo transactional endpoint',
  )
  assert(capturedInit?.method === 'POST', 'Expected POST request')
  const headers = new Headers(capturedInit?.headers)
  assert(headers.get('api-key') === 'secret-api-key', 'Expected Brevo API key header')
  assert(headers.get('authorization') === null, 'Must not use bearer auth for Brevo')
  assert(headers.get('accept') === 'application/json', 'Expected JSON response accept header')
  assert(
    headers.get('content-type') === 'application/json',
    'Expected JSON request content type',
  )

  const payload = JSON.parse(String(capturedInit?.body)) as Record<string, unknown>
  assertDeepEquals(payload, {
    sender: {
      email: 'horus@example.com',
      name: 'H.O.R.U.S System',
    },
    to: [
      {
        email: 'invitee@example.com',
      },
    ],
    subject: 'Invitation subject',
    htmlContent: '<p>Invitation HTML</p>',
  })
  assert(!('textContent' in payload), 'Expected one documented Brevo body type')
})

Deno.test('maps Brevo non-success responses to typed delivery failure', async () => {
  const sender = new BrevoCompanyInvitationEmailSender(
    {
      apiKey: 'secret-api-key',
      fromEmail: 'horus@example.com',
      fromName: 'H.O.R.U.S System',
    },
    async () => new Response('provider failure', { status: 400 }),
    () => {},
  )

  const error = await assertRejects(
    () => sender.send(testMessage()),
    CompanyInvitationDeliveryFailedError,
  )
  assert(
    error.message === 'company_invitation_delivery_failed',
    'Expected stable sanitized failure code',
  )
  assert(!error.message.includes('secret-api-key'), 'Must not expose provider credential')
})

Deno.test('reports only Brevo response status for provider diagnostics', async () => {
  const statuses: number[] = []
  const sender = new BrevoCompanyInvitationEmailSender(
    {
      apiKey: 'secret-api-key',
      fromEmail: 'horus@example.com',
      fromName: 'H.O.R.U.S System',
    },
    async () => new Response('sensitive provider body', { status: 401 }),
    (status) => statuses.push(status),
  )

  await assertRejects(
    () => sender.send(testMessage()),
    CompanyInvitationDeliveryFailedError,
  )

  assertDeepEquals(statuses, [401])
})

Deno.test('maps Brevo network failures to typed delivery failure', async () => {
  const sender = new BrevoCompanyInvitationEmailSender(
    {
      apiKey: 'secret-api-key',
      fromEmail: 'horus@example.com',
      fromName: 'H.O.R.U.S System',
    },
    async () => {
      throw new Error('network details')
    },
  )

  const error = await assertRejects(
    () => sender.send(testMessage()),
    CompanyInvitationDeliveryFailedError,
  )
  assert(
    error.message === 'company_invitation_delivery_failed',
    'Expected stable sanitized failure code',
  )
  assert(!error.message.includes('network details'), 'Must not expose provider failure details')
})

function testMessage() {
  return {
    to: 'invitee@example.com',
    subject: 'Invitation subject',
    text: 'Invitation text',
    html: '<p>Invitation HTML</p>',
  }
}

async function assertRejects<T extends Error>(
  action: () => Promise<void>,
  errorType: new (...args: never[]) => T,
): Promise<T> {
  try {
    await action()
  } catch (error) {
    assert(error instanceof errorType, `Expected ${errorType.name}`)
    return error
  }
  throw new Error(`Expected ${errorType.name} to be thrown`)
}

function assert(condition: boolean, message: string): asserts condition {
  if (!condition) throw new Error(message)
}

function assertDeepEquals(actual: unknown, expected: unknown): void {
  const actualJson = JSON.stringify(actual)
  const expectedJson = JSON.stringify(expected)
  assert(actualJson === expectedJson, `Expected ${expectedJson}, got ${actualJson}`)
}
