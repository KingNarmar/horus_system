import '../../../company/domain/entities/company_role.dart';

/// UX/application permission gate mirrored by protected server authorization.
/// No tenant content can be read with this policy alone.
abstract final class EntitlementVisibilityPolicy {
  static bool canView(CompanyRole role) => switch (role) {
    CompanyRole.owner || CompanyRole.admin => true,
    CompanyRole.operations ||
    CompanyRole.accountant ||
    CompanyRole.viewer ||
    CompanyRole.driver => false,
  };
}
