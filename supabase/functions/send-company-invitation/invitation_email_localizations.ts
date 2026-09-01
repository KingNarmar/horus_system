export type InvitationEmailLocaleCopy = {
  subject: string
  brandName: string
  brandTagline: string
  sectionLabel: string
  heroTitle: (companyName: string) => string
  invited: (roleLabel: string) => string
  authInstruction: string
  companyLabel: string
  roleDetailLabel: string
  expiresLabel: string
  linkLabel: string
  codeLabel: string
  manualCodeInstruction: string
  securityNote: string
  footerReason: string
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
  brandName: 'H.O.R.U.S System',
  brandTagline: 'Heavy Operations & Route Unified System',
  sectionLabel: 'Company invitation',
  heroTitle: (companyName) => `Join ${companyName}`,
  invited: (roleLabel) => `You were invited with the role ${roleLabel}.`,
  authInstruction:
    'Sign in or create an account using the invited email address, then review and explicitly accept the invitation.',
  companyLabel: 'Company',
  roleDetailLabel: 'Role',
  expiresLabel: 'Expires',
  linkLabel: 'Review invitation',
  codeLabel: 'Invitation code',
  manualCodeInstruction:
    'If the button does not open H.O.R.U.S System, open the invitation screen manually and paste this code.',
  securityNote:
    'Keep this invitation code private. H.O.R.U.S System verifies the signed-in email before the invitation can be accepted.',
  footerReason: 'You received this email because a company invited you to H.O.R.U.S System.',
  roleLabel: (role) => englishRoleLabels[role] ?? 'Member',
}

export const invitationEmailArabic: InvitationEmailLocaleCopy = {
  subject: 'دعوة للانضمام إلى الشركة',
  brandName: 'H.O.R.U.S System',
  brandTagline: 'نظام موحّد لإدارة عمليات النقل الثقيل والمسارات',
  sectionLabel: 'دعوة للانضمام إلى شركة',
  heroTitle: (companyName) => `انضم إلى ${companyName}`,
  invited: (roleLabel) => `تمت دعوتك بصلاحية ${roleLabel}.`,
  authInstruction:
    'سجّل الدخول أو أنشئ حسابًا باستخدام البريد الإلكتروني المدعو، ثم راجع الدعوة واقبلها بشكل صريح.',
  companyLabel: 'الشركة',
  roleDetailLabel: 'الصلاحية',
  expiresLabel: 'تنتهي في',
  linkLabel: 'مراجعة الدعوة',
  codeLabel: 'رمز الدعوة',
  manualCodeInstruction:
    'إذا لم يفتح الزر H.O.R.U.S System، افتح شاشة الدعوة يدويًا والصق هذا الرمز.',
  securityNote:
    'احتفظ برمز الدعوة بشكل خاص. يتحقق H.O.R.U.S System من البريد الإلكتروني للحساب المسجل قبل السماح بقبول الدعوة.',
  footerReason: 'وصلتك هذه الرسالة لأن إحدى الشركات دعتك للانضمام إلى H.O.R.U.S System.',
  roleLabel: (role) => arabicRoleLabels[role] ?? 'عضو',
}
