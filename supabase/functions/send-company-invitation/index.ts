import {
  CompanyInvitationDeliveryFailedError,
  CompanyInvitationDeliveryNotConfiguredError,
  createCompanyInvitationEmailSender,
} from './company_invitation_email_sender.ts'
import {
  buildInvitationUrl,
  generateRawToken,
  hashTokenForPostgres,
} from './company_invitation_token.ts'
import { buildCompanyInvitationEmail } from './invitation_email_template.ts'
import {
  confirmInvitationDelivery,
  loadCompanyName,
  prepareNewInvitation,
  prepareResend,
  readEnvironment,
  requiredString,
} from './supabase_user_api_client.ts'

type InvitationAction = 'send' | 'resend'

type InvitationRequest = {
  action?: unknown
  company_id?: unknown
  email?: unknown
  role?: unknown
  invitation_id?: unknown
}

const corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'authorization, apikey, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
}

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders })
  }

  if (request.method !== 'POST') {
    return jsonResponse(405, 'company_invitation_request_invalid')
  }

  const authorization = request.headers.get('authorization')?.trim()
  if (!authorization?.toLowerCase().startsWith('bearer ')) {
    return jsonResponse(401, 'company_auth_required')
  }

  const environment = readEnvironment()
  const sender = createCompanyInvitationEmailSender()
  if (!environment || !sender.isConfigured) {
    return jsonResponse(503, 'company_invitation_delivery_not_configured')
  }

  const body = await readRequest(request)
  if (!body) {
    return jsonResponse(400, 'company_invitation_request_invalid')
  }

  const action = parseAction(body.action)
  const companyId = requiredString(body.company_id)
  if (!action || !companyId) {
    return jsonResponse(400, 'company_invitation_request_invalid')
  }

  const companyNameResult = await loadCompanyName({
    environment,
    authorization,
    companyId,
  })
  if (!companyNameResult.ok) {
    return jsonResponse(companyNameResult.status, companyNameResult.code)
  }

  const rawToken = generateRawToken()
  const tokenHash = await hashTokenForPostgres(rawToken)
  const preparationResult = action === 'send'
    ? await prepareNewInvitation({
        environment,
        authorization,
        companyId,
        email: requiredString(body.email),
        role: requiredString(body.role),
        tokenHash,
      })
    : await prepareResend({
        environment,
        authorization,
        companyId,
        invitationId: requiredString(body.invitation_id),
        tokenHash,
      })

  if (!preparationResult.ok) {
    return jsonResponse(preparationResult.status, preparationResult.code)
  }

  const preparation = preparationResult.data
  const emailContent = buildCompanyInvitationEmail({
    companyName: companyNameResult.companyName,
    inviteUrl: buildInvitationUrl(environment.appUrl, rawToken),
    invitationCode: rawToken,
    role: preparation.invitation_role,
    expiresAt: preparation.expires_at,
  })

  const deliveryFailureCode = await sendInvitationEmail({
    sender,
    email: preparation.email_normalized,
    emailContent,
  })
  if (deliveryFailureCode) {
    return jsonResponse(502, deliveryFailureCode)
  }

  const confirmationResult = await confirmInvitationDelivery({
    environment,
    authorization,
    preparation,
  })
  if (!confirmationResult.ok) {
    return jsonResponse(
      502,
      'company_invitation_delivery_confirmation_unknown',
    )
  }

  return new Response(
    JSON.stringify({
      ok: true,
      invitation_id: preparation.invitation_id,
    }),
    { status: 200, headers: responseHeaders() },
  )
})

async function readRequest(request: Request): Promise<InvitationRequest | null> {
  try {
    return await request.json() as InvitationRequest
  } catch (_) {
    return null
  }
}

function parseAction(value: unknown): InvitationAction | null {
  return value === 'send' || value === 'resend' ? value : null
}

async function sendInvitationEmail(input: {
  sender: ReturnType<typeof createCompanyInvitationEmailSender>
  email: string
  emailContent: ReturnType<typeof buildCompanyInvitationEmail>
}): Promise<string | null> {
  try {
    await input.sender.send({
      to: input.email,
      ...input.emailContent,
    })
    return null
  } catch (error) {
    if (error instanceof CompanyInvitationDeliveryNotConfiguredError) {
      return 'company_invitation_delivery_not_configured'
    }
    if (error instanceof CompanyInvitationDeliveryFailedError) {
      return 'company_invitation_delivery_failed'
    }
    return 'company_invitation_delivery_failed'
  }
}

function jsonResponse(status: number, code: string): Response {
  return new Response(JSON.stringify({ ok: false, code }), {
    status,
    headers: responseHeaders(),
  })
}

function responseHeaders(): HeadersInit {
  return {
    ...corsHeaders,
    'content-type': 'application/json',
  }
}
