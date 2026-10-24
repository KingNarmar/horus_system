import 'package:test/test.dart';

import '../../../scripts/security/verify_issue_317_r44_signed_jwt_draft_denials.dart';

void main() {
  group('Issue 317 R4.4 signed-JWT negative draft contract', () {
    for (final role in ['owner', 'admin', 'accountant']) {
      test('$role passes own authorization but cannot submit invalid data', () {
        expect(
          expectedIssue317R44DraftSqlstate(role: role, foreign: false),
          'P2814',
        );
        expect(
          expectedIssue317R44DraftSqlstate(role: role, foreign: true),
          'P2813',
        );
      });
    }

    for (final role in ['operations', 'viewer', 'driver', 'anonymous']) {
      test('$role cannot create drafts in either tenant', () {
        expect(
          expectedIssue317R44DraftSqlstate(role: role, foreign: false),
          'P2813',
        );
        expect(
          expectedIssue317R44DraftSqlstate(role: role, foreign: true),
          'P2813',
        );
      });
    }

    test('unknown roles cannot be treated as finance roles', () {
      expect(
        expectedIssue317R44DraftSqlstate(
          role: 'unsupported',
          foreign: false,
        ),
        isNull,
      );
    });
  });
}
