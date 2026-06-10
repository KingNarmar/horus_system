enum CompanyRole { owner, admin, operations, accountant, viewer, driver }

extension CompanyRoleX on CompanyRole {
  String get value {
    return switch (this) {
      CompanyRole.owner => 'owner',
      CompanyRole.admin => 'admin',
      CompanyRole.operations => 'operations',
      CompanyRole.accountant => 'accountant',
      CompanyRole.viewer => 'viewer',
      CompanyRole.driver => 'driver',
    };
  }
}
