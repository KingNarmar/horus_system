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
  pageBackground: '#f2f4f7',
  cardBackground: '#ffffff',
  brandBackground: '#0b1f33',
  brandAccent: '#d6a84b',
  textPrimary: '#172033',
  textSecondary: '#667085',
  border: '#dfe4ea',
  softSurface: '#f8fafc',
  codeSurface: '#f2f5f8',
  noteSurface: '#f7f8fa',
  buttonBackground: '#0b1f33',
  buttonText: '#ffffff',
  badgeBackground: '#edf1f5',
  badgeText: '#243247',
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
    invitationEmailEnglish.brandName,
    invitationEmailEnglish.heroTitle(companyName),
    invitationEmailEnglish.invited(englishRole),
    invitationEmailEnglish.authInstruction,
    `${invitationEmailEnglish.companyLabel}: ${companyName}`,
    `${invitationEmailEnglish.roleDetailLabel}: ${englishRole}`,
    `${invitationEmailEnglish.expiresLabel}: ${englishExpiresAt}`,
    `${invitationEmailEnglish.linkLabel}: ${inviteUrl}`,
    `${invitationEmailEnglish.codeLabel}: ${invitationCode}`,
    invitationEmailEnglish.manualCodeInstruction,
    invitationEmailEnglish.securityNote,
    '',
    invitationEmailArabic.brandName,
    invitationEmailArabic.heroTitle(companyName),
    invitationEmailArabic.invited(arabicRole),
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
      ${escapeHtml(invitationEmailEnglish.heroTitle(companyName))}
    </div>
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;background:${invitationEmailTheme.pageBackground};">
      <tr>
        <td align="center" style="padding:32px 14px;">
          <table role="presentation" width="620" cellspacing="0" cellpadding="0" border="0" style="width:100%;max-width:620px;background:${invitationEmailTheme.cardBackground};border:1px solid ${invitationEmailTheme.border};border-radius:14px;overflow:hidden;">
            <tr>
              <td style="background:${invitationEmailTheme.brandBackground};padding:28px 32px;font-family:Arial,Helvetica,sans-serif;">
                <div style="font-size:21px;line-height:27px;font-weight:700;color:#ffffff;letter-spacing:0.2px;">${escapeHtml(invitationEmailEnglish.brandName)}</div>
                <div style="margin-top:5px;font-size:11px;line-height:17px;font-weight:700;letter-spacing:1.1px;color:${invitationEmailTheme.brandAccent};text-transform:uppercase;">${escapeHtml(invitationEmailEnglish.brandTagline)}</div>
              </td>
            </tr>
            <tr>
              <td dir="ltr" style="padding:34px 32px 32px;font-family:Arial,Helvetica,sans-serif;color:${invitationEmailTheme.textPrimary};">
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
              <td align="center" style="padding:24px 32px 28px;background:${invitationEmailTheme.softSurface};border-top:1px solid ${invitationEmailTheme.border};font-family:Arial,Helvetica,sans-serif;color:${invitationEmailTheme.textSecondary};">
                <div style="font-size:13px;line-height:19px;font-weight:700;color:${invitationEmailTheme.textPrimary};">${escapeHtml(invitationEmailEnglish.brandName)}</div>
                <div style="margin-top:3px;font-size:11px;line-height:17px;">${escapeHtml(invitationEmailEnglish.brandTagline)}</div>
                <div style="margin-top:12px;font-size:11px;line-height:17px;">${escapeHtml(invitationEmailEnglish.footerReason)}</div>
                <div dir="rtl" lang="ar" style="margin-top:5px;font-family:Tahoma,Arial,sans-serif;font-size:11px;line-height:18px;">${escapeHtml(invitationEmailArabic.footerReason)}</div>
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

  return `
    <div style="font-size:11px;line-height:17px;font-weight:700;letter-spacing:1.1px;text-transform:uppercase;color:${invitationEmailTheme.brandAccent};">${escapeHtml(input.copy.sectionLabel)}</div>
    <h1 style="margin:7px 0 0;font-size:28px;line-height:36px;font-weight:700;color:${invitationEmailTheme.textPrimary};">${escapeHtml(input.copy.heroTitle(input.companyName))}</h1>
    <div style="margin-top:12px;">
      <span style="display:inline-block;padding:6px 10px;background:${invitationEmailTheme.badgeBackground};border-radius:999px;font-size:12px;line-height:16px;font-weight:700;color:${invitationEmailTheme.badgeText};">${escapeHtml(input.roleLabel)}</span>
    </div>
    <p style="margin:16px 0 0;font-size:15px;line-height:24px;color:${invitationEmailTheme.textPrimary};">${escapeHtml(input.copy.invited(input.roleLabel))}</p>
    <p style="margin:8px 0 0;font-size:13px;line-height:21px;color:${invitationEmailTheme.textSecondary};">${escapeHtml(input.copy.authInstruction)}</p>

    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-top:24px;width:100%;background:${invitationEmailTheme.softSurface};border:1px solid ${invitationEmailTheme.border};border-radius:10px;">
      ${renderDetailRow(input.copy.companyLabel, input.companyName, textAlign, false)}
      ${renderDetailRow(input.copy.roleDetailLabel, input.roleLabel, textAlign, false)}
      ${renderDetailRow(input.copy.expiresLabel, input.expiresAt, textAlign, true)}
    </table>

    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-top:24px;width:100%;">
      <tr>
        <td align="center" bgcolor="${invitationEmailTheme.buttonBackground}" style="border-radius:9px;background:${invitationEmailTheme.buttonBackground};">
          <a href="${escapeHtml(input.inviteUrl)}" style="display:block;padding:14px 20px;font-size:15px;line-height:20px;font-weight:700;color:${invitationEmailTheme.buttonText};text-decoration:none;border-radius:9px;text-align:center;">${escapeHtml(input.copy.linkLabel)}</a>
        </td>
      </tr>
    </table>

    <div style="margin-top:26px;font-size:12px;line-height:18px;font-weight:700;color:${invitationEmailTheme.textPrimary};">${escapeHtml(input.copy.codeLabel)}</div>
    <div dir="ltr" style="margin-top:8px;padding:16px;background:${invitationEmailTheme.codeSurface};border:1px solid ${invitationEmailTheme.border};border-radius:9px;font-family:Consolas,'Courier New',monospace;font-size:16px;line-height:24px;font-weight:600;letter-spacing:0.5px;color:${invitationEmailTheme.textPrimary};text-align:left;word-break:break-all;">${escapeHtml(input.invitationCode)}</div>
    <p style="margin:9px 0 0;font-size:12px;line-height:19px;color:${invitationEmailTheme.textSecondary};">${escapeHtml(input.copy.manualCodeInstruction)}</p>

    <div style="margin-top:20px;padding:13px 14px;background:${invitationEmailTheme.noteSurface};border:1px solid ${invitationEmailTheme.border};border-radius:8px;font-size:12px;line-height:19px;color:${invitationEmailTheme.textSecondary};">${escapeHtml(input.copy.securityNote)}</div>
  `
}

function renderDetailRow(
  label: string,
  value: string,
  textAlign: 'left' | 'right',
  forceLtrValue: boolean,
): string {
  const valueDirection = forceLtrValue ? ' dir="ltr"' : ''
  const valueAlign = forceLtrValue ? 'left' : textAlign

  return `
    <tr>
      <td style="padding:13px 16px;border-bottom:1px solid ${invitationEmailTheme.border};font-size:12px;line-height:18px;font-weight:700;color:${invitationEmailTheme.textSecondary};text-align:${textAlign};width:34%;">${escapeHtml(label)}</td>
      <td${valueDirection} style="padding:13px 16px;border-bottom:1px solid ${invitationEmailTheme.border};font-size:13px;line-height:19px;font-weight:600;color:${invitationEmailTheme.textPrimary};text-align:${valueAlign};">${escapeHtml(value)}</td>
    </tr>
  `
}

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;')
}
