import { formatInvitationExpiry } from './invitation_email_expiry_formatter.ts'
import {
  invitationEmailArabic,
  invitationEmailEnglish,
} from './invitation_email_localizations.ts'

export type CompanyInvitationEmailTemplateInput = {
  companyName: string
  inviteUrl: string
  invitationCode: string
  role: string
  expiresAt: string
}

export type CompanyInvitationEmailContent = {
  subject: string
  text: string
  html: string
}

export function buildCompanyInvitationEmail(
  input: CompanyInvitationEmailTemplateInput,
): CompanyInvitationEmailContent {
  const companyName = input.companyName.trim()
  const inviteUrl = input.inviteUrl.trim()
  const invitationCode = input.invitationCode.trim()
  const role = input.role.trim()
  const expiresAt = input.expiresAt.trim()

  const englishRole = invitationEmailEnglish.roleLabel(role)
  const arabicRole = invitationEmailArabic.roleLabel(role)
  const englishExpiresAt = formatInvitationExpiry(expiresAt, 'en')
  const arabicExpiresAt = formatInvitationExpiry(expiresAt, 'ar')
  const subject = `${invitationEmailEnglish.subject} | ${invitationEmailArabic.subject}`

  const text = [
    invitationEmailEnglish.invited(companyName, englishRole),
    invitationEmailEnglish.authInstruction,
    `${invitationEmailEnglish.linkLabel}: ${inviteUrl}`,
    `${invitationEmailEnglish.codeLabel}: ${invitationCode}`,
    invitationEmailEnglish.manualCodeInstruction,
    invitationEmailEnglish.expires(englishExpiresAt),
    '',
    invitationEmailArabic.invited(companyName, arabicRole),
    invitationEmailArabic.authInstruction,
    `${invitationEmailArabic.linkLabel}: ${inviteUrl}`,
    `${invitationEmailArabic.codeLabel}: ${invitationCode}`,
    invitationEmailArabic.manualCodeInstruction,
    invitationEmailArabic.expires(arabicExpiresAt),
  ].join('\n')

  const html = `
<!doctype html>
<html lang="en">
  <body>
    <section dir="ltr">
      <h2>${escapeHtml(invitationEmailEnglish.heading)}</h2>
      <p>${escapeHtml(invitationEmailEnglish.invited(companyName, englishRole))}</p>
      <p>${escapeHtml(invitationEmailEnglish.authInstruction)}</p>
      <p><a href="${escapeHtml(inviteUrl)}">${escapeHtml(invitationEmailEnglish.linkLabel)}</a></p>
      <p><strong>${escapeHtml(invitationEmailEnglish.codeLabel)}:</strong> <code>${escapeHtml(invitationCode)}</code></p>
      <p>${escapeHtml(invitationEmailEnglish.manualCodeInstruction)}</p>
      <p>${escapeHtml(invitationEmailEnglish.expires(englishExpiresAt))}</p>
    </section>
    <hr />
    <section dir="rtl" lang="ar">
      <h2>${escapeHtml(invitationEmailArabic.heading)}</h2>
      <p>${escapeHtml(invitationEmailArabic.invited(companyName, arabicRole))}</p>
      <p>${escapeHtml(invitationEmailArabic.authInstruction)}</p>
      <p><a href="${escapeHtml(inviteUrl)}">${escapeHtml(invitationEmailArabic.linkLabel)}</a></p>
      <p><strong>${escapeHtml(invitationEmailArabic.codeLabel)}:</strong> <code dir="ltr">${escapeHtml(invitationCode)}</code></p>
      <p>${escapeHtml(invitationEmailArabic.manualCodeInstruction)}</p>
      <p>${escapeHtml(invitationEmailArabic.expires(arabicExpiresAt))}</p>
    </section>
  </body>
</html>`

  return { subject, text, html }
}

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;')
}
