import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/subscriptions/domain/policies/subscriptions_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  test('only company owners can view subscriptions', () {
    for (final role in CompanyRole.values) {
      expect(
        SubscriptionsPermissionPolicy.canViewSubscriptions(role),
        role == CompanyRole.owner,
      );
    }
  });
}
