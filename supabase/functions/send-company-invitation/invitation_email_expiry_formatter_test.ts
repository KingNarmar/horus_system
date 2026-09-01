import { formatInvitationExpiry } from './invitation_email_expiry_formatter.ts'

Deno.test('formats invitation expiry in readable English UTC', () => {
  const formatted = formatInvitationExpiry('2026-09-06T12:00:00Z', 'en')

  assertEquals(formatted, 'Sep 6, 2026, 12:00 PM UTC')
})

Deno.test('formats invitation expiry using Arabic locale and UTC', () => {
  const formatted = formatInvitationExpiry('2026-09-06T12:00:00Z', 'ar')

  assertContains(formatted, 'UTC')
  assertContains(formatted, 'م')
  assertNotContains(formatted, '2026-09-06T12:00:00Z')
})

Deno.test('preserves trimmed invalid invitation expiry instead of throwing', () => {
  const formatted = formatInvitationExpiry('  invalid-expiry  ', 'en')

  assertEquals(formatted, 'invalid-expiry')
})

function assertEquals(actual: string, expected: string): void {
  if (actual !== expected) {
    throw new Error(`Expected ${expected}, received ${actual}`)
  }
}

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
