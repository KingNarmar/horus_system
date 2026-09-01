import { formatInvitationExpiry } from './invitation_email_expiry_formatter.ts'
import {
  invitationEmailArabic,
  invitationEmailEnglish,
  type InvitationEmailLocaleCopy,
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

const invitationEmailTheme = {
  pageBackground: '#f3f5f7',
  cardBackground: '#ffffff',
  brandBackground: '#0b1f33',
  brandAccent: '#d6a84b',
  textPrimary: '#172033',
  textSecondary: '#5f6b7a',
  border: '#dfe4ea',
  softSurface: '#f7f9fb',
  codeSurface: '#eef2f6',
  securitySurface: '#fff8e8',
  securityBorder: '#ead7a3',
  buttonBackground: '#0b1f33',
  buttonText: '#ffffff',
} as const

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
    invitationEmailEnglish.heading,
    invitationEmailEnglish.invited(companyName, englishRole),
    invitationEmailEnglish.authInstruction,
    `${invitationEmailEnglish.companyLabel}: ${companyName}`,
    `${invitationEmailEnglish.roleDetailLabel}: ${englishRole}`,
    `${invitationEmailEnglish.expiresLabel}: ${englishExpiresAt}`,
    `${invitationEmailEnglish.linkLabel}: ${inviteUrl}`,
    `${invitationEmailEnglish.codeLabel}: ${invitationCode}`,
    invitationEmailEnglish.manualCodeInstruction,
    invitationEmailEnglish.securityNote,
    '',
    invitationEmailArabic.heading,
    invitationEmailArabic.invited(companyName, arabicRole),
    invitationEmailArabic.authInstruction,
    `${invitationEmailArabic.companyLabel}: ${companyName}`,
    `${invitationEmailArabic.roleDetailLabel}: ${arabicRole}`,
    `${invitationEmailArabic.expiresLabel}: ${arabicExpiresAt}`,
    `${invitationEmailArabic.linkLabel}: ${inviteUrl}`,
    `${invitationEmailArabic.codeLabel}: ${invitationCode}`,
    invitationEmailArabic.manualCodeInstruction,
    invitationEmailArabic.securityNote,
  ].join('\n')

  const html = `
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${escapeHtml(subject)}</title>
  </head>
  <body style="margin:0;padding:0;background:${invitationEmailTheme.pageBackground};">
    <div style="display:none;max-height:0;overflow:hidden;opacity:0;">
      ${escapeHtml(invitationEmailEnglish.invited(companyName, englishRole))}
    </div>
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;background:${invitationEmailTheme.pageBackground};">
      <tr>
        <td align="center" style="padding:32px 16px;">
          <table role="presentation" width="640" cellspacing="0" cellpadding="0" border="0" style="width:100%;max-width:640px;background:${invitationEmailTheme.cardBackground};border:1px solid ${invitationEmailTheme.border};border-radius:14px;overflow:hidden;">
            <tr>
              <td style="background:${invitationEmailTheme.brandBackground};padding:28px 32px 24px;font-family:Arial,Helvetica,sans-serif;">
                <div style="font-size:12px;line-height:18px;font-weight:700;letter-spacing:2.4px;color:${invitationEmailTheme.brandAccent};">H.O.R.U.S SYSTEM</div>
                <div style="margin-top:8px;font-size:23px;line-height:30px;font-weight:700;color:#ffffff;">${escapeHtml(invitationEmailEnglish.subject.replace('H.O.R.U.S System — ', ''))}</div>
              </td>
            </tr>
            <tr>
              <td dir="ltr" style="padding:32px;font-family:Arial,Helvetica,sans-serif;color:${invitationEmailTheme.textPrimary};">
                ${renderLocaleSection({
                  copy: invitationEmailEnglish,
                  companyName,
                  roleLabel: englishRole,
                  expiresAt: englishExpiresAt,
                  inviteUrl,
                  invitationCode,
                  direction: 'ltr',
                })}
              </td>
            </tr>
            <tr>
              <td style="padding:0 32px;">
                <div style="height:1px;background:${invitationEmailTheme.border};font-size:1px;line-height:1px;">&nbsp;</div>
              </td>
            </tr>
            <tr>
              <td dir="rtl" lang="ar" style="padding:32px;font-family:Tahoma,Arial,sans-serif;color:${invitationEmailTheme.textPrimary};text-align:right;">
                ${renderLocaleSection({
                  copy: invitationEmailArabic,
                  companyName,
                  roleLabel: arabicRole,
                  expiresAt: arabicExpiresAt,
                  inviteUrl,
                  invitationCode,
                  direction: 'rtl',
                })}
              </td>
            </tr>
            <tr>
              <td align="center" style="padding:20px 32px 28px;background:${invitationEmailTheme.softSurface};border-top:1px solid ${invitationEmailTheme.border};font-family:Arial,Helvetica,sans-serif;font-size:12px;line-height:18px;color:${invitationEmailTheme.textSecondary};">
                H.O.R.U.S System
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`

  return { subject, text, html }
}

function renderLocaleSection(input: {
  copy: InvitationEmailLocaleCopy
  companyName: string
  roleLabel: string
  expiresAt: string
  inviteUrl: string
  invitationCode: string
  direction: 'ltr' | 'rtl'
}): string {
  const textAlign = input.direction === 'rtl' ? 'right' : 'left'
  const codeAlign = input.direction === 'rtl' ? 'right' : 'left'

  return `
    <h1 style="margin:0;font-size:24px;line-height:32px;font-weight:700;color:${invitationEmailTheme.textPrimary};">${escapeHtml(input.copy.heading)}</h1>
    <p style="margin:12px 0 0;font-size:16px;line-height:25px;color:${invitationEmailTheme.textPrimary};">${escapeHtml(input.copy.invited(input.companyName, input.roleLabel))}</p>
    <p style="margin:10px 0 0;font-size:14px;line-height:22px;color:${invitationEmailTheme.textSecondary};">${escapeHtml(input.copy.authInstruction)}</p>

    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-top:24px;width:100%;background:${invitationEmailTheme.softSurface};border:1px solid ${invitationEmailTheme.border};border-radius:10px;">
      <tr>
        <td style="padding:18px 20px;font-size:13px;line-height:20px;color:${invitationEmailTheme.textSecondary};text-align:${textAlign};">
          <div style="font-weight:700;color:${invitationEmailTheme.textPrimary};margin-bottom:10px;">${escapeHtml(input.copy.detailsTitle)}</div>
          ${renderDetail(input.copy.companyLabel, input.companyName)}
          ${renderDetail(input.copy.roleDetailLabel, input.roleLabel)}
          ${renderDetail(input.copy.expiresLabel, input.expiresAt)}
        </td>
      </tr>
    </table>

    <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin-top:24px;">
      <tr>
        <td bgcolor="${invitationEmailTheme.buttonBackground}" style="border-radius:8px;background:${invitationEmailTheme.buttonBackground};">
          <a href="${escapeHtml(input.inviteUrl)}" style="display:inline-block;padding:13px 22px;font-size:15px;line-height:20px;font-weight:700;color:${invitationEmailTheme.buttonText};text-decoration:none;border-radius:8px;">${escapeHtml(input.copy.linkLabel)}</a>
        </td>
      </tr>
    </table>

    <div style="margin-top:24px;font-size:12px;line-height:18px;font-weight:700;color:${invitationEmailTheme.textSecondary};">${escapeHtml(input.copy.codeLabel)}</div>
    <div dir="ltr" style="margin-top:8px;padding:14px 16px;background:${invitationEmailTheme.codeSurface};border:1px solid ${invitationEmailTheme.border};border-radius:8px;font-family:Consolas,'Courier New',monospace;font-size:14px;line-height:20px;letter-spacing:0.4px;color:${invitationEmailTheme.textPrimary};text-align:${codeAlign};word-break:break-all;">${escapeHtml(input.invitationCode)}</div>
    <p style="margin:10px 0 0;font-size:12px;line-height:19px;color:${invitationEmailTheme.textSecondary};">${escapeHtml(input.copy.manualCodeInstruction)}</p>

    <div style="margin-top:20px;padding:12px 14px;background:${invitationEmailTheme.securitySurface};border:1px solid ${invitationEmailTheme.securityBorder};border-radius:8px;font-size:12px;line-height:19px;color:${invitationEmailTheme.textSecondary};">${escapeHtml(input.copy.securityNote)}</div>
  `
}

function renderDetail(label: string, value: string): string {
  return `<div style="margin-top:6px;"><strong style="color:${invitationEmailTheme.textPrimary};">${escapeHtml(label)}:</strong> ${escapeHtml(value)}</div>`
}

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;')
}
