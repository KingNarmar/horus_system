import {
  prepareNewInvitation,
  prepareResend,
} from './supabase_user_api_client.ts'

Deno.test('invitation RPC safely forwards the exact seats-quota error', async () => {
  const previousFetch = globalThis.fetch
  const environment = {
    supabaseUrl: 'http://localhost',
    publishableKey: 'test-publishable-key',
    appUrl: 'http://localhost',
    confirmationSecret: 'test-secret',
  }

  const send = () => prepareNewInvitation({
    environment,
    authorization: 'Bearer test-user-jwt',
    companyId: 'company-test',
    email: 'invitee@example.com',
    role: 'viewer',
    tokenHash: '\\x1234',
  })
  const resend = () => prepareResend({
    environment,
    authorization: 'Bearer test-user-jwt',
    companyId: 'company-test',
    invitationId: 'invitation-test',
    tokenHash: '\\x1234',
  })

  const cases = [
    {
      databaseMessage: 'quota_company_users_reached',
      expectedCode: 'quota_company_users_reached',
    },
    {
      databaseMessage: 'company_invitation_permission_denied',
      expectedCode: 'company_invitation_permission_denied',
    },
    {
      databaseMessage: 'quota_unrecognized_internal_detail',
      expectedCode: 'server_error',
    },
    {
      databaseMessage: 'private_database_internal_detail',
      expectedCode: 'server_error',
    },
  ]

  try {
    for (const { databaseMessage, expectedCode } of cases) {
      globalThis.fetch = async (_input, init) => {
        if (init?.method !== 'POST') {
          throw new Error('Expected a POST to the invitation RPC')
        }
        return new Response(
          JSON.stringify({ message: databaseMessage, code: 'P2860' }),
          { status: 400, headers: { 'content-type': 'application/json' } },
        )
      }

      for (const invoke of [send, resend]) {
        const result = await invoke()
        if (result.ok || result.status !== 400 || result.code !== expectedCode) {
          throw new Error(
            `Unexpected sanitized invitation failure for ${databaseMessage}`,
          )
        }
      }
    }
  } finally {
    globalThis.fetch = previousFetch
  }
})
