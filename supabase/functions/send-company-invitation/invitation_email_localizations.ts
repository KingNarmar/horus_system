export type InvitationEmailLocaleCopy = {
  subject: string
  heading: string
  invited: (companyName: string, roleLabel: string) => string
  authInstruction: string
  detailsTitle: string
  companyLabel: string
  roleDetailLabel: string
  expiresLabel: string
  linkLabel: string
  codeLabel: string
  manualCodeInstruction: string
  securityNote: string
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
  heading: 'You are invited to H.O.R.U.S System',
  invited: (companyName, roleLabel) =>
    `You have been invited to join ${companyName} with the role ${roleLabel}.`,
  authInstruction:
    'Sign in or create an account using the invited email address, then review and explicitly accept the invitation.',
  detailsTitle: 'Invitation details',
  companyLabel: 'Company',
  roleDetailLabel: 'Role',
  expiresLabel: 'Expires',
  linkLabel: 'Review invitation',
  codeLabel: 'Invitation code',
  manualCodeInstruction:
    'If the button does not open H.O.R.U.S System, open the invitation screen manually and paste the invitation code.',
  securityNote:
    'Keep this invitation code private. H.O.R.U.S System verifies the signed-in email before the invitation can be accepted.',
  expires: (expiresAt) => `Expires: ${expiresAt}`,
  roleLabel: (role) => englishRoleLabels[role] ?? 'Member',
}

export const invitationEmailArabic: InvitationEmailLocaleCopy = {
  subject: 'دعوة للانضمام إلى الشركة',
  heading: 'لديك دعوة للانضمام إلى H.O.R.U.S System',
  invited: (companyName, roleLabel) =>
    `تمت دعوتك للانضمام إلى ${companyName} بصلاحية ${roleLabel}.`,
  authInstruction:
    'سجّل الدخول أو أنشئ حسابًا باستخدام البريد الإلكتروني المدعو، ثم راجع الدعوة واقبلها بشكل صريح.',
  detailsTitle: 'تفاصيل الدعوة',
  companyLabel: 'الشركة',
  roleDetailLabel: 'الصلاحية',
  expiresLabel: 'تنتهي في',
  linkLabel: 'مراجعة الدعوة',
  codeLabel: 'رمز الدعوة',
  manualCodeInstruction:
    'إذا لم يفتح الزر H.O.R.U.S System، افتح شاشة الدعوة يدويًا والصق رمز الدعوة.',
  securityNote:
    'احتفظ برمز الدعوة بشكل خاص. يتحقق H.O.R.U.S System من البريد الإلكتروني للحساب المسجل قبل السماح بقبول الدعوة.',
  expires: (expiresAt) => `تنتهي صلاحية الدعوة: ${expiresAt}`,
  roleLabel: (role) => arabicRoleLabels[role] ?? 'عضو',
}
