import {
  CompanyInvitationDeliveryFailedError,
  CompanyInvitationDeliveryNotConfiguredError,
  createCompanyInvitationEmailSender,
} from './company_invitation_email_sender.ts'
import { buildCompanyInvitationEmail } from './invitation_email_template.ts'

type InvitationAction = 'send' | 'resend'

type InvitationRequest = {
  action?: unknown
  company_id?: unknown
  email?: unknown
  role?: unknown
  invitation_id?: unknown
}

type EdgeEnvironment = {
  supabaseUrl: string
  publishableKey: string
  appUrl: string
}

type PreparedInvitation = {
  invitation_id: string
  company_id: string
  email_normalized: string
  invitation_role: string
  expires_at: string
  delivery_attempt_id: string
}

type RpcResult =
  | { ok: true; data: unknown }
  | { ok: false; status: number; code: string }

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

  let body: InvitationRequest
  try {
    body = await request.json() as InvitationRequest
  } catch (_) {
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
    roleLabel: bilingualRoleLabel(preparation.invitation_role),
    expiresAt: preparation.expires_at,
  })

  try {
    await sender.send({
      to: preparation.email_normalized,
      ...emailContent,
    })
  } catch (error) {
    if (error instanceof CompanyInvitationDeliveryNotConfiguredError) {
      return jsonResponse(503, 'company_invitation_delivery_not_configured')
    }
    if (error instanceof CompanyInvitationDeliveryFailedError) {
      return jsonResponse(502, 'company_invitation_delivery_failed')
    }
    return jsonResponse(502, 'company_invitation_delivery_failed')
  }

  const confirmationResult = await callRpc({
    environment,
    authorization,
    functionName: 'confirm_company_invitation_delivery',
    body: {
      p_company_id: preparation.company_id,
      p_invitation_id: preparation.invitation_id,
      p_delivery_attempt_id: preparation.delivery_attempt_id,
    },
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
    {
      status: 200,
      headers: responseHeaders(),
    },
  )
})

function parseAction(value: unknown): InvitationAction | null {
  return value === 'send' || value === 'resend' ? value : null
}

function requiredString(value: unknown): string | null {
  if (typeof value !== 'string') return null
  const normalized = value.trim()
  return normalized.length > 0 ? normalized : null
}

function readEnvironment(): EdgeEnvironment | null {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim()
  const publishableKey = readPublishableKey()
  const appUrl = Deno.env.get('HORUS_INVITATION_APP_URL')?.trim()

  if (!supabaseUrl || !publishableKey || !appUrl) return null
  return { supabaseUrl, publishableKey, appUrl }
}

function readPublishableKey(): string | null {
  const singleKey = Deno.env.get('SUPABASE_PUBLISHABLE_KEY')?.trim()
  if (singleKey) return singleKey

  const keyMap = Deno.env.get('SUPABASE_PUBLISHABLE_KEYS')?.trim()
  if (keyMap) {
    try {
      const parsed = JSON.parse(keyMap) as Record<string, unknown>
      const defaultKey = parsed.default
      if (typeof defaultKey === 'string' && defaultKey.trim()) {
        return defaultKey.trim()
      }
    } catch (_) {
      return null
    }
  }

  const legacyAnonKey = Deno.env.get('SUPABASE_ANON_KEY')?.trim()
  return legacyAnonKey || null
}

async function loadCompanyName(input: {
  environment: EdgeEnvironment
  authorization: string
  companyId: string
}): Promise<
  | { ok: true; companyName: string }
  | { ok: false; status: number; code: string }
> {
  const query = new URLSearchParams({
    id: `eq.${input.companyId}`,
    select: 'name',
    limit: '1',
  })

  let response: Response
  try {
    response = await fetch(
      `${input.environment.supabaseUrl}/rest/v1/companies?${query.toString()}`,
      {
        headers: userApiHeaders(input.environment, input.authorization),
      },
    )
  } catch (_) {
    return { ok: false, status: 503, code: 'server_error' }
  }

  if (!response.ok) {
    return {
      ok: false,
      status: mapHttpStatus(response.status),
      code: 'server_error',
    }
  }

  const rows = await safeJson(response)
  if (!Array.isArray(rows) || rows.length !== 1) {
    return { ok: false, status: 404, code: 'company_not_found' }
  }

  const name = requiredString((rows[0] as Record<string, unknown>).name)
  if (!name) {
    return { ok: false, status: 404, code: 'company_not_found' }
  }

  return { ok: true, companyName: name }
}

async function prepareNewInvitation(input: {
  environment: EdgeEnvironment
  authorization: string
  companyId: string
  email: string | null
  role: string | null
  tokenHash: string
}): Promise<
  | { ok: true; data: PreparedInvitation }
  | { ok: false; status: number; code: string }
> {
  if (!input.email || !input.role) {
    return failureResult(400, 'company_invitation_request_invalid')
  }

  return prepareInvitationRpc({
    environment: input.environment,
    authorization: input.authorization,
    functionName: 'prepare_company_invitation',
    body: {
      p_company_id: input.companyId,
      p_email: input.email,
      p_role: input.role,
      p_token_hash: input.tokenHash,
    },
  })
}

async function prepareResend(input: {
  environment: EdgeEnvironment
  authorization: string
  companyId: string
  invitationId: string | null
  tokenHash: string
}): Promise<
  | { ok: true; data: PreparedInvitation }
  | { ok: false; status: number; code: string }
> {
  if (!input.invitationId) {
    return failureResult(400, 'company_invitation_request_invalid')
  }

  return prepareInvitationRpc({
    environment: input.environment,
    authorization: input.authorization,
    functionName: 'prepare_company_invitation_resend',
    body: {
      p_company_id: input.companyId,
      p_invitation_id: input.invitationId,
      p_token_hash: input.tokenHash,
    },
  })
}

async function prepareInvitationRpc(input: {
  environment: EdgeEnvironment
  authorization: string
  functionName: string
  body: Record<string, unknown>
}): Promise<
  | { ok: true; data: PreparedInvitation }
  | { ok: false; status: number; code: string }
> {
  const result = await callRpc(input)
  if (!result.ok) return result

  if (!Array.isArray(result.data) || result.data.length !== 1) {
    return failureResult(502, 'server_error')
  }

  const row = result.data[0] as Record<string, unknown>
  const preparation: PreparedInvitation = {
    invitation_id: requiredString(row.invitation_id) ?? '',
    company_id: requiredString(row.company_id) ?? '',
    email_normalized: requiredString(row.email_normalized) ?? '',
    invitation_role: requiredString(row.invitation_role) ?? '',
    expires_at: requiredString(row.expires_at) ?? '',
    delivery_attempt_id: requiredString(row.delivery_attempt_id) ?? '',
  }

  if (Object.values(preparation).some((value) => value.length === 0)) {
    return failureResult(502, 'server_error')
  }

  return { ok: true, data: preparation }
}

async function callRpc(input: {
  environment: EdgeEnvironment
  authorization: string
  functionName: string
  body: Record<string, unknown>
}): Promise<RpcResult> {
  let response: Response
  try {
    response = await fetch(
      `${input.environment.supabaseUrl}/rest/v1/rpc/${input.functionName}`,
      {
        method: 'POST',
        headers: userApiHeaders(input.environment, input.authorization),
        body: JSON.stringify(input.body),
      },
    )
  } catch (_) {
    return failureResult(503, 'server_error')
  }

  const data = await safeJson(response)
  if (response.ok) return { ok: true, data }

  return failureResult(
    mapHttpStatus(response.status),
    extractSemanticCode(data) ?? 'server_error',
  )
}

function userApiHeaders(
  environment: EdgeEnvironment,
  authorization: string,
): HeadersInit {
  return {
    'authorization': authorization,
    'apikey': environment.publishableKey,
    'content-type': 'application/json',
  }
}

function extractSemanticCode(data: unknown): string | null {
  if (!data || typeof data !== 'object') return null
  const message = (data as Record<string, unknown>).message
  if (typeof message !== 'string') return null
  return message.startsWith('company_') ? message : null
}

function failureResult(status: number, code: string) {
  return { ok: false as const, status, code }
}

function mapHttpStatus(status: number): number {
  if (status === 401 || status === 403 || status === 404 || status === 409) {
    return status
  }
  return status >= 400 && status < 500 ? 400 : 502
}

function generateRawToken(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(32))
  const binary = String.fromCharCode(...bytes)
  return btoa(binary)
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '')
}

async function hashTokenForPostgres(rawToken: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(rawToken),
  )
  const hex = Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
  return `\\x${hex}`
}

function buildInvitationUrl(appUrl: string, rawToken: string): string {
  const url = new URL('/company/invitation', appUrl)
  url.searchParams.set('token', rawToken)
  return url.toString()
}

function bilingualRoleLabel(role: string): string {
  switch (role) {
    case 'admin':
      return 'Admin / مسؤول'
    case 'operations':
      return 'Operations / العمليات'
    case 'accountant':
      return 'Accountant / المحاسب'
    case 'viewer':
      return 'Viewer / عرض فقط'
    case 'driver':
      return 'Driver / سائق'
    default:
      return 'Member / عضو'
  }
}

async function safeJson(response: Response): Promise<unknown> {
  try {
    return await response.json()
  } catch (_) {
    return null
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
