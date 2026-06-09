class CompanyPermissions {
  final bool canViewCompanyUsers;
  final bool canInviteCompanyUsers;
  final bool canChangeCompanyUserRole;
  final bool canDeactivateCompanyUser;
  final bool canManageCompanySettings;

  const CompanyPermissions({
    required this.canViewCompanyUsers,
    required this.canInviteCompanyUsers,
    required this.canChangeCompanyUserRole,
    required this.canDeactivateCompanyUser,
    required this.canManageCompanySettings,
  });
}
