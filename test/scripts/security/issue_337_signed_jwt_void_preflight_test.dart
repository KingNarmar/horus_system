import 'package:flutter_test/flutter_test.dart';

import '../../../scripts/security/verify_issue_337_signed_jwt_void.dart'
    as signedJwt;

void main() {
  test('accepts five-group canonical UUIDs used by Issue 337 fixtures', () {
    for (final id in [
      '00000000-0000-0000-0000-000000000001',
      '041a7fc8-3593-41f2-b00f-99643277b18f',
      'e49d3e66-fb55-40ee-b1ba-49c3719fa61c',
    ]) {
      expect(signedJwt.isIssue337FixtureUuid(id), isTrue);
    }
  });

  test('rejects missing-group, malformed and unsafe fixture UUIDs', () {
    for (final id in [
      '00000000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000001 ',
      '00000000-0000-0000-0000-00000000000Z',
      '',
    ]) {
      expect(signedJwt.isIssue337FixtureUuid(id), isFalse);
    }
  });
}
