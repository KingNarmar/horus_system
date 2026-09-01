import { buildCompanyInvitationEmail } from './invitation_email_template.ts'

Deno.test('renders branded bilingual invitation email with clear actions', () => {
  const content = buildCompanyInvitationEmail({
    companyName: 'Horus Transport',
    inviteUrl: 'https://example.com/company/invitation?token=raw-token',
    invitationCode: 'raw-token',
    role: 'operations',
    expiresAt: '2026-09-06T12:00:00Z',
  })

  assertContains(content.subject, 'Company invitation')
  assertContains(content.subject, 'دعوة للانضمام إلى الشركة')
  assertContains(content.text, 'Company: Horus Transport')
  assertContains(content.text, 'Role: Operations')
  assertContains(content.text, 'الشركة: Horus Transport')
  assertContains(content.text, 'الصلاحية: العمليات')
  assertContains(content.text, 'Invitation code: raw-token')
  assertContains(content.text, 'رمز الدعوة: raw-token')
  assertContains(content.text, 'Expires: Sep 6, 2026, 12:00 PM UTC')
  assertContains(content.text, 'UTC')
  assertNotContains(content.text, '2026-09-06T12:00:00Z')

  assertContains(content.html, 'H.O.R.U.S SYSTEM')
  assertContains(content.html, 'role="presentation"')
  assertContains(content.html, 'href="https://example.com/company/invitation?token=raw-token"')
  assertContains(content.html, '>Review invitation</a>')
  assertContains(content.html, 'dir="rtl" lang="ar"')
  assertContains(content.html, 'dir="ltr"')
  assertContains(content.html, 'Invitation details')
  assertContains(content.html, 'تفاصيل الدعوة')
  assertContains(content.html, 'raw-token')
})

Deno.test('escapes dynamic invitation email values in html', () => {
  const content = buildCompanyInvitationEmail({
    companyName: '<script>alert(1)</script>',
    inviteUrl: 'https://example.com/?token="unsafe"',
    invitationCode: '<raw&token>',
    role: 'viewer',
    expiresAt: '<date>',
  })

  assertNotContains(content.html, '<script>alert(1)</script>')
  assertContains(content.html, '&lt;script&gt;alert(1)&lt;/script&gt;')
  assertContains(content.html, 'token=&quot;unsafe&quot;')
  assertContains(content.html, '&lt;raw&amp;token&gt;')
  assertContains(content.html, '&lt;date&gt;')
})

Deno.test('keeps security guidance localized in both email sections', () => {
  const content = buildCompanyInvitationEmail({
    companyName: 'Horus Transport',
    inviteUrl: 'https://example.com/invitation',
    invitationCode: 'safe-code',
    role: 'viewer',
    expiresAt: '2026-09-06T12:00:00Z',
  })

  assertContains(content.text, 'Keep this invitation code private.')
  assertContains(content.text, 'احتفظ برمز الدعوة بشكل خاص.')
  assertContains(content.html, 'Keep this invitation code private.')
  assertContains(content.html, 'احتفظ برمز الدعوة بشكل خاص.')
})

function assertContains(value: string, expected: string): void {
  if (!value.includes(expected)) {
    throw new Error(`Expected value to contain: ${expected}`)
  }
}

function assertNotContains(value: string, unexpected: string): void {
  if (value.includes(unexpected)) {
    throw new Error(`Expected value not to contain: ${unexpected}`)
  }
}
