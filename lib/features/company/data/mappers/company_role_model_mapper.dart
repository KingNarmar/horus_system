import '../../domain/entities/company_role.dart';

abstract final class CompanyRoleModelMapper {
  static CompanyRole fromDatabaseValue(String? value) {
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
