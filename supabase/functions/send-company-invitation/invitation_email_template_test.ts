import { buildCompanyInvitationEmail } from './invitation_email_template.ts'

Deno.test('renders bilingual invitation email with manual code fallback', () => {
  const content = buildCompanyInvitationEmail({
    companyName: 'Horus Transport',
    inviteUrl: 'https://example.com/company/invitation?token=raw-token',
    invitationCode: 'raw-token',
    role: 'operations',
    expiresAt: '2026-09-06T12:00:00Z',
  })

  assertContains(content.subject, 'Company invitation')
  assertContains(content.subject, 'دعوة للانضمام إلى الشركة')
  assertContains(content.text, 'Operations')
  assertContains(content.text, 'العمليات')
  assertContains(content.text, 'Invitation code: raw-token')
  assertContains(content.text, 'رمز الدعوة: raw-token')
  assertContains(content.html, '<code>raw-token</code>')
  assertContains(content.html, '<code dir="ltr">raw-token</code>')
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
  assertContains(content.html, '&lt;raw&amp;token&gt;')
  assertContains(content.html, '&lt;date&gt;')
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
