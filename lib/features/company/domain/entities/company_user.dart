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

  String get title {
    final normalizedDisplayName = displayName?.trim();

    if (normalizedDisplayName != null && normalizedDisplayName.isNotEmpty) {
      return normalizedDisplayName;
    }

    return 'Unknown User';
  }

  String get subtitle {
    final normalizedPhone = phone?.trim();

    if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
      return normalizedPhone;
    }

    return 'Profile details not set yet';
  }
}
