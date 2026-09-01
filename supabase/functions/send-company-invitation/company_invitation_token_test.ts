import {
  buildInvitationUrl,
  generateRawToken,
  hashTokenForPostgres,
} from './company_invitation_token.ts'

Deno.test('generates URL-safe 256-bit invitation tokens', () => {
  const first = generateRawToken()
  const second = generateRawToken()

  assert(first.length === 43, 'Expected base64url token length of 43 characters')
  assert(/^[A-Za-z0-9_-]+$/.test(first), 'Expected URL-safe token characters')
  assert(first !== second, 'Expected independently generated invitation tokens')
})

Deno.test('hashes invitation token as 32-byte PostgreSQL bytea hex', async () => {
  const hash = await hashTokenForPostgres('token-value')

  assert(
    hash ===
      '\\xe6c02a5742ea9d4de588eb9b9de7bed43dc17011552186bed3e98b2c5958ff4a',
    'Expected deterministic SHA-256 PostgreSQL bytea value',
  )
})

Deno.test('builds public invitation handoff URL with token only', () => {
  const url = buildInvitationUrl('https://kingnarmar.com/base', 'raw-token')
  const parsed = new URL(url)

  assert(parsed.origin === 'https://kingnarmar.com', 'Expected public app origin')
  assert(parsed.pathname === '/horus/invitation', 'Expected invitation handoff path')
  assert(parsed.searchParams.get('token') === 'raw-token', 'Expected token query')
  assert(parsed.searchParams.size === 1, 'Expected token to be the only authority')
})

function assert(condition: boolean, message: string): void {
  if (!condition) throw new Error(message)
}
