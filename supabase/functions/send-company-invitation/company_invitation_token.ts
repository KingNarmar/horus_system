export function generateRawToken(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(32))
  const binary = String.fromCharCode(...bytes)
  return btoa(binary)
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '')
}

export async function hashTokenForPostgres(rawToken: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(rawToken),
  )
  const hex = Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
  return `\\x${hex}`
}

export function buildInvitationUrl(appUrl: string, rawToken: string): string {
  const url = new URL('/company/invitation', appUrl)
  url.searchParams.set('token', rawToken)
  return url.toString()
}

export function bilingualRoleLabel(role: string): string {
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
