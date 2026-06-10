import '../policies/company_permission_policy.dart';
import 'company.dart';
import 'company_role.dart';

class CurrentCompanyContext {
  final Company company;
  final CompanyRole role;

  const CurrentCompanyContext({required this.company, required this.role});

  String get companyId => company.id;

  bool get canManageCompany {
    return CompanyPermissionPolicy.canManageCompanySettings(role);
  }
}
