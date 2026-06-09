import 'company.dart';
import 'company_role.dart';

class CompanyMembership {
  final Company company;
  final CompanyRole role;
  final bool isActive;

  const CompanyMembership({
    required this.company,
    required this.role,
    required this.isActive,
  });
}
