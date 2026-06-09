enum CompanyRole {
  owner,
  admin,
  operations,
  accountant,
  viewer,
  driver,
}

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

  String get label {
    return switch (this) {
      CompanyRole.owner => 'Owner',
      CompanyRole.admin => 'Admin',
      CompanyRole.operations => 'Operations',
      CompanyRole.accountant => 'Accountant',
      CompanyRole.viewer => 'Viewer',
      CompanyRole.driver => 'Driver',
    };
  }
}

abstract final class CompanyRoleMapper {
  static CompanyRole fromValue(String? value) {
    return switch (value) {
      'owner' => CompanyRole.owner,
      'admin' => CompanyRole.admin,
      'operations' => CompanyRole.operations,
      'accountant' => CompanyRole.accountant,
      'viewer' => CompanyRole.viewer,
      'driver' => CompanyRole.driver,
      _ => CompanyRole.viewer,
    };
  }
}
