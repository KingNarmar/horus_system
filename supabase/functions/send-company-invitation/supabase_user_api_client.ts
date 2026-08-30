export type EdgeEnvironment = {
  supabaseUrl: string
  publishableKey: string
  appUrl: string
}

export type PreparedInvitation = {
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

type PreparedInvitationResult =
  | { ok: true; data: PreparedInvitation }
  | { ok: false; status: number; code: string }

export function requiredString(value: unknown): string | null {
  if (typeof value !== 'string') return null
  const normalized = value.trim()
  return normalized.length > 0 ? normalized : null
}

export function readEnvironment(): EdgeEnvironment | null {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim()
  const publishableKey = readPublishableKey()
  const appUrl = Deno.env.get('HORUS_INVITATION_APP_URL')?.trim()

  if (!supabaseUrl || !publishableKey || !appUrl) return null
  return { supabaseUrl, publishableKey, appUrl }
}

export async function loadCompanyName(input: {
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
    return failureResult(503, 'server_error')
  }

  if (!response.ok) {
    return failureResult(mapHttpStatus(response.status), 'server_error')
  }

  const rows = await safeJson(response)
  if (!Array.isArray(rows) || rows.length !== 1) {
    return failureResult(404, 'company_not_found')
  }

  const name = requiredString((rows[0] as Record<string, unknown>).name)
  return name
    ? { ok: true, companyName: name }
    : failureResult(404, 'company_not_found')
}

export function prepareNewInvitation(input: {
  environment: EdgeEnvironment
  authorization: string
  companyId: string
  email: string | null
  role: string | null
  tokenHash: string
}): Promise<PreparedInvitationResult> {
  if (!input.email || !input.role) {
    return Promise.resolve(
      failureResult(400, 'company_invitation_request_invalid'),
    )
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

export function prepareResend(input: {
  environment: EdgeEnvironment
  authorization: string
  companyId: string
  invitationId: string | null
  tokenHash: string
}): Promise<PreparedInvitationResult> {
  if (!input.invitationId) {
    return Promise.resolve(
      failureResult(400, 'company_invitation_request_invalid'),
    )
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

export async function confirmInvitationDelivery(input: {
  environment: EdgeEnvironment
  authorization: string
  preparation: PreparedInvitation
}): Promise<RpcResult> {
  return callRpc({
    environment: input.environment,
    authorization: input.authorization,
    functionName: 'confirm_company_invitation_delivery',
    body: {
      p_company_id: input.preparation.company_id,
      p_invitation_id: input.preparation.invitation_id,
      p_delivery_attempt_id: input.preparation.delivery_attempt_id,
    },
  })
}

async function prepareInvitationRpc(input: {
  environment: EdgeEnvironment
  authorization: string
  functionName: string
  body: Record<string, unknown>
}): Promise<PreparedInvitationResult> {
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

async function safeJson(response: Response): Promise<unknown> {
  try {
    return await response.json()
  } catch (_) {
    return null
  }
}
