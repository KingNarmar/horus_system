import { buildCompanyInvitationEmail } from './invitation_email_template.ts'

Deno.test('renders premium bilingual invitation email with branded hierarchy', () => {
  const content = buildCompanyInvitationEmail({
    companyName: 'Horus Transport',
    inviteUrl: 'https://example.com/company/invitation?token=raw-token',
    invitationCode: 'raw-token',
    role: 'operations',
    expiresAt: '2026-09-06T12:00:00Z',
  })

  assertContains(content.subject, 'Company invitation')
  assertContains(content.subject, 'دعوة للانضمام إلى الشركة')
  assertContains(content.text, 'Join Horus Transport')
  assertContains(content.text, 'انضم إلى Horus Transport')
  assertContains(content.text, 'Company: Horus Transport')
  assertContains(content.text, 'Role: Operations')
  assertContains(content.text, 'الشركة: Horus Transport')
  assertContains(content.text, 'الصلاحية: العمليات')
  assertContains(content.text, 'Invitation code: raw-token')
  assertContains(content.text, 'رمز الدعوة: raw-token')
  assertContains(content.text, 'Expires: Sep 6, 2026, 12:00 PM UTC')
  assertNotContains(content.text, '2026-09-06T12:00:00Z')

  assertContains(content.html, '>H.O.R.U.S System</div>')
  assertContains(content.html, 'Heavy Operations &amp; Route Unified System')
  assertContains(content.html, 'Join Horus Transport')
  assertContains(content.html, 'انضم إلى Horus Transport')
  assertContains(content.html, 'role="presentation"')
  assertContains(content.html, 'href="https://example.com/company/invitation?token=raw-token"')
  assertContains(content.html, '>Review invitation</a>')
  assertContains(content.html, '>مراجعة الدعوة</a>')
  assertContains(content.html, 'dir="rtl" lang="ar"')
  assertContains(content.html, 'dir="ltr"')
  assertContains(content.html, 'border-radius:999px')
  assertContains(content.html, 'font-family:Consolas')
  assertContains(content.html, 'raw-token')
})

Deno.test('keeps expiry and invitation code left-to-right inside Arabic section', () => {
  const content = buildCompanyInvitationEmail({
    companyName: 'Horus Transport',
    inviteUrl: 'https://example.com/invitation',
    invitationCode: 'safe-code-123',
    role: 'viewer',
    expiresAt: '2026-09-06T12:00:00Z',
  })

  assertContains(content.html, 'dir="rtl" lang="ar"')
  assertContains(content.html, 'dir="ltr" style="margin-top:8px;padding:16px')
  assertContains(content.html, 'safe-code-123')
  assertContains(content.html, 'Sep 6, 2026, 12:00 PM UTC')
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

Deno.test('keeps localized security guidance and footer context', () => {
  const content = buildCompanyInvitationEmail({
    companyName: 'Horus Transport',
    inviteUrl: 'https://example.com/invitation',
    invitationCode: 'safe-code',
    role: 'viewer',
    expiresAt: '2026-09-06T12:00:00Z',
  })

  assertContains(content.text, 'Keep this invitation code private.')
  assertContains(content.text, 'احتفظ برمز الدعوة بشكل خاص.')
  assertContains(content.html, 'You received this email because a company invited you')
  assertContains(content.html, 'وصلتك هذه الرسالة لأن إحدى الشركات دعتك')
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
