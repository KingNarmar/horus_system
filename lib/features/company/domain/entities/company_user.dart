import 'company_role.dart';

class CompanyUser {
  final String id;
  final String companyId;
  final String userId;
  final String? displayName;
  final String? phone;
  final CompanyRole role;
  final bool isActive;

  const CompanyUser({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.role,
    required this.isActive,
    this.displayName,
    this.phone,
  });
}
