// Issue #317 R5.1 — Development-only security smoke contracts.
// No valid membership ID is ever submitted by the mutation probes.

import 'issue_317_r44_dev_test_client.dart';

const r51NonexistentMembershipId =
    '00000000-0000-0000-0000-000000000000';

String r51MembershipTopic(String userId) =>
    'realtime:horus:user:$userId:membership';

Map<String, Object?> r51DeniedRoleChangeProbe(String companyId) => {
  'p_company_id': companyId,
  'p_membership_id': r51NonexistentMembershipId,
  'p_new_role': 'operations',
};

Map<String, Object?> r51DeniedStatusProbe(String companyId) => {
  'p_company_id': companyId,
  'p_membership_id': r51NonexistentMembershipId,
};

/// A different SQLSTATE (e.g. nonexistent target, malformed request or
/// expired token) cannot be counted as proof of an authorization denial.
bool r51ExpectedPermissionDenial(R44Reply reply, String expectedCode) =>
    !reply.ok &&
    reply.status >= 400 &&
    reply.status < 500 &&
    reply.sqlState == expectedCode;
