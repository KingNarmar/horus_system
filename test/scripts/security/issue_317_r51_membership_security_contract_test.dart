import 'package:test/test.dart';
import 'package:horus_system/features/company/data/constants/company_membership_realtime_topics.dart';

import '../../../scripts/security/issue_317_r44_dev_test_client.dart';
import '../../../scripts/security/issue_317_r51_membership_security_contract.dart';

void main() {
  const userId = '01020304-0506-4708-890a-0b0c0d0e0f10';
  const companyId = 'f1020304-0506-4708-890a-0b0c0d0e0f10';

  test('personal private topic matches app Data layer topic', () {
    expect(
      r51MembershipTopic(userId),
      'realtime:${CompanyMembershipRealtimeTopics.userMemberships(userId)}',
    );
  });

  test('role and status permission probes can never target a known row', () {
    expect(r51NonexistentMembershipId, '00000000-0000-0000-0000-000000000000');
    final roleChange = r51DeniedRoleChangeProbe(companyId);
    expect(roleChange, {
      'p_company_id': companyId,
      'p_membership_id': r51NonexistentMembershipId,
      'p_new_role': 'operations',
    });
    expect(r51DeniedStatusProbe(companyId), {
      'p_company_id': companyId,
      'p_membership_id': r51NonexistentMembershipId,
    });
    expect(roleChange.containsKey('p_user_id'), isFalse);
  });

  test('only expected server authorization SQLSTATE is PASS', () {
    expect(
      r51ExpectedPermissionDenial(
        const R44Reply(400, {'code': 'P2823'}),
        'P2823',
      ),
      isTrue,
    );
    expect(
      r51ExpectedPermissionDenial(
        const R44Reply(403, {'code': 'P2826'}),
        'P2826',
      ),
      isTrue,
    );

    for (final reply in [
      const R44Reply(200, null),
      const R44Reply(204, null),
      const R44Reply(400, {'code': 'P2824'}),
      const R44Reply(400, {'code': 'P2821'}),
      const R44Reply(401, {'code': 'PGRST301'}),
      const R44Reply(500, {'code': 'P2823'}),
      const R44Reply(400, 'permission denied'),
    ]) {
      expect(r51ExpectedPermissionDenial(reply, 'P2823'), isFalse);
    }
  });
}
