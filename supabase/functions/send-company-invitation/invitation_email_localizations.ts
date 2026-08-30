export type InvitationEmailLocaleCopy = {
  subject: string
  heading: string
  invited: (companyName: string, roleLabel: string) => string
  authInstruction: string
  linkLabel: string
  codeLabel: string
  manualCodeInstruction: string
  expires: (expiresAt: string) => string
  roleLabel: (role: string) => string
}

const englishRoleLabels: Record<string, string> = {
  admin: 'Admin',
  operations: 'Operations',
  accountant: 'Accountant',
  viewer: 'Viewer',
  driver: 'Driver',
}

const arabicRoleLabels: Record<string, string> = {
  admin: 'مسؤول',
  operations: 'العمليات',
  accountant: 'المحاسب',
  viewer: 'عرض فقط',
  driver: 'سائق',
}

export const invitationEmailEnglish: InvitationEmailLocaleCopy = {
  subject: 'H.O.R.U.S System — Company invitation',
  heading: 'H.O.R.U.S System company invitation',
  invited: (companyName, roleLabel) =>
    `You have been invited to join ${companyName} on H.O.R.U.S System with the role ${roleLabel}.`,
  authInstruction:
    'Sign in or create an account using the invited email address, then review and explicitly accept the invitation.',
  linkLabel: 'Review invitation',
  codeLabel: 'Invitation code',
  manualCodeInstruction:
    'If the link does not open H.O.R.U.S System, open the invitation screen manually and paste the invitation code.',
  expires: (expiresAt) => `Expires: ${expiresAt}`,
  roleLabel: (role) => englishRoleLabels[role] ?? 'Member',
}

export const invitationEmailArabic: InvitationEmailLocaleCopy = {
  subject: 'دعوة للانضمام إلى الشركة',
  heading: 'دعوة للانضمام إلى شركة على H.O.R.U.S System',
  invited: (companyName, roleLabel) =>
    `تمت دعوتك للانضمام إلى ${companyName} على H.O.R.U.S System بصلاحية ${roleLabel}.`,
  authInstruction:
    'سجّل الدخول أو أنشئ حسابًا باستخدام البريد الإلكتروني المدعو، ثم راجع الدعوة واقبلها بشكل صريح.',
  linkLabel: 'مراجعة الدعوة',
  codeLabel: 'رمز الدعوة',
  manualCodeInstruction:
    'إذا لم يفتح الرابط H.O.R.U.S System، افتح شاشة الدعوة يدويًا والصق رمز الدعوة.',
  expires: (expiresAt) => `تنتهي صلاحية الدعوة: ${expiresAt}`,
  roleLabel: (role) => arabicRoleLabels[role] ?? 'عضو',
}
