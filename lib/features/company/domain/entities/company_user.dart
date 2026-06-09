import 'company_role.dart';

class CompanyUser {
  final String id;
  final String companyId;
  final String userId;
  final String? displayName;
  final String? email;
  final CompanyRole role;
  final bool isActive;

  const CompanyUser({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.role,
    required this.isActive,
    this.displayName,
    this.email,
  });

  String get title {
    final normalizedDisplayName = displayName?.trim();

    if (normalizedDisplayName != null && normalizedDisplayName.isNotEmpty) {
      return normalizedDisplayName;
    }

    final normalizedEmail = email?.trim();

    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      return normalizedEmail;
    }

    return userId;
  }
}
