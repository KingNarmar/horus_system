export type CompanyInvitationEmailTemplateInput = {
  companyName: string
  inviteUrl: string
  invitationCode: string
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
  const invitationCode = input.invitationCode.trim()
  const expiresAt = input.expiresAt.trim()

  const subject = `H.O.R.U.S System — Company invitation | دعوة للانضمام إلى الشركة`
  const text = [
    `You have been invited to join ${companyName} on H.O.R.U.S System with the role ${roleLabel}.`,
    `Open the invitation link and sign in or create an account using the invited email address. Acceptance is always explicit.`,
    `Invitation link: ${inviteUrl}`,
    `Invitation code: ${invitationCode}`,
    `If the link does not open H.O.R.U.S System, open the invitation screen manually and paste the invitation code.`,
    `Expires: ${expiresAt}`,
    '',
    `تمت دعوتك للانضمام إلى ${companyName} على H.O.R.U.S System بصلاحية ${roleLabel}.`,
    `افتح رابط الدعوة ثم سجّل الدخول أو أنشئ حسابًا باستخدام البريد الإلكتروني المدعو. قبول الدعوة يتم بشكل صريح فقط.`,
    `رابط الدعوة: ${inviteUrl}`,
    `رمز الدعوة: ${invitationCode}`,
    `إذا لم يفتح الرابط H.O.R.U.S System، افتح شاشة الدعوة يدويًا والصق رمز الدعوة.`,
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
      <p><strong>Invitation code:</strong> <code>${escapeHtml(invitationCode)}</code></p>
      <p>If the link does not open H.O.R.U.S System, open the invitation screen manually and paste the invitation code.</p>
      <p>Expires: ${escapeHtml(expiresAt)}</p>
    </section>
    <hr />
    <section dir="rtl" lang="ar">
      <h2>دعوة للانضمام إلى شركة على H.O.R.U.S System</h2>
      <p>تمت دعوتك للانضمام إلى <strong>${escapeHtml(companyName)}</strong> بصلاحية <strong>${escapeHtml(roleLabel)}</strong>.</p>
      <p>سجّل الدخول أو أنشئ حسابًا باستخدام البريد الإلكتروني المدعو، ثم راجع الدعوة واقبلها بشكل صريح.</p>
      <p><a href="${escapeHtml(inviteUrl)}">مراجعة الدعوة</a></p>
      <p><strong>رمز الدعوة:</strong> <code dir="ltr">${escapeHtml(invitationCode)}</code></p>
      <p>إذا لم يفتح الرابط H.O.R.U.S System، افتح شاشة الدعوة يدويًا والصق رمز الدعوة.</p>
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
