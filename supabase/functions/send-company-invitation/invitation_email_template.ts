export type CompanyInvitationEmailTemplateInput = {
  companyName: string
  inviteUrl: string
  roleLabel: string
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
  const roleLabel = input.roleLabel.trim()
  const inviteUrl = input.inviteUrl.trim()
  const expiresAt = input.expiresAt.trim()

  const subject = `H.O.R.U.S System — Company invitation | دعوة للانضمام إلى الشركة`
  const text = [
    `You have been invited to join ${companyName} on H.O.R.U.S System with the role ${roleLabel}.`,
    `Open the invitation link and sign in or create an account using the invited email address. Acceptance is always explicit.`,
    `Invitation link: ${inviteUrl}`,
    `Expires: ${expiresAt}`,
    '',
    `تمت دعوتك للانضمام إلى ${companyName} على H.O.R.U.S System بصلاحية ${roleLabel}.`,
    `افتح رابط الدعوة ثم سجّل الدخول أو أنشئ حسابًا باستخدام البريد الإلكتروني المدعو. قبول الدعوة يتم بشكل صريح فقط.`,
    `رابط الدعوة: ${inviteUrl}`,
    `تنتهي صلاحية الدعوة: ${expiresAt}`,
  ].join('\n')

  const html = `
<!doctype html>
<html lang="en">
  <body>
    <section dir="ltr">
      <h2>H.O.R.U.S System company invitation</h2>
      <p>You have been invited to join <strong>${escapeHtml(companyName)}</strong> with the role <strong>${escapeHtml(roleLabel)}</strong>.</p>
      <p>Sign in or create an account using the invited email address, then review and explicitly accept the invitation.</p>
      <p><a href="${escapeHtml(inviteUrl)}">Review invitation</a></p>
      <p>Expires: ${escapeHtml(expiresAt)}</p>
    </section>
    <hr />
    <section dir="rtl" lang="ar">
      <h2>دعوة للانضمام إلى شركة على H.O.R.U.S System</h2>
      <p>تمت دعوتك للانضمام إلى <strong>${escapeHtml(companyName)}</strong> بصلاحية <strong>${escapeHtml(roleLabel)}</strong>.</p>
      <p>سجّل الدخول أو أنشئ حسابًا باستخدام البريد الإلكتروني المدعو، ثم راجع الدعوة واقبلها بشكل صريح.</p>
      <p><a href="${escapeHtml(inviteUrl)}">مراجعة الدعوة</a></p>
      <p>تنتهي صلاحية الدعوة: ${escapeHtml(expiresAt)}</p>
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
