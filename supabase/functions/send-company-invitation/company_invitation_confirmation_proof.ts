export type InvitationConfirmationAction = 'confirm' | 'abort'

export async function signInvitationConfirmation(input: {
  secret: string
  companyId: string
  invitationId: string
  deliveryAttemptId: string
  action: InvitationConfirmationAction
}): Promise<string> {
  const encoder = new TextEncoder()
  const secretHash = await crypto.subtle.digest(
    'SHA-256',
    encoder.encode(input.secret),
  )
  const signingKey = await crypto.subtle.importKey(
    'raw',
    secretHash,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const signedPayload = [
    input.companyId,
    input.invitationId,
    input.deliveryAttemptId,
    input.action,
  ].join(':')
  const signature = await crypto.subtle.sign(
    'HMAC',
    signingKey,
    encoder.encode(signedPayload),
  )
  const hex = Array.from(new Uint8Array(signature))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
  return '\\x' + hex
}
