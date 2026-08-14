import '../../../company/domain/entities/company_role.dart';

abstract final class SubscriptionsPermissionPolicy {
  static bool canViewSubscriptions(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner => true,
      CompanyRole.admin ||
      CompanyRole.operations ||
      CompanyRole.accountant ||
      CompanyRole.viewer ||
      CompanyRole.driver => false,
    };
  }
}
