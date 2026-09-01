export type InvitationEmailExpiryLocale = 'en' | 'ar'

const localeTags: Record<InvitationEmailExpiryLocale, string> = {
  en: 'en-US',
  ar: 'ar-EG',
}

export function formatInvitationExpiry(
  expiresAt: string,
  locale: InvitationEmailExpiryLocale,
): string {
  const normalizedExpiresAt = expiresAt.trim()
  if (normalizedExpiresAt.length === 0) return normalizedExpiresAt

  const expiryDate = new Date(normalizedExpiresAt)
  if (Number.isNaN(expiryDate.getTime())) return normalizedExpiresAt

  return new Intl.DateTimeFormat(localeTags[locale], {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    timeZone: 'UTC',
    timeZoneName: 'short',
  }).format(expiryDate)
}
