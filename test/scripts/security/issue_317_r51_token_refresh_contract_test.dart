import 'dart:convert';

import 'package:test/test.dart';

import '../../../scripts/security/issue_317_r51_token_refresh_contract.dart';

const _userA = '11111111-1111-4111-8111-111111111111';
const _userB = '22222222-2222-4222-8222-222222222222';
const _companyA = '33333333-3333-4333-8333-333333333333';

final _now = DateTime.utc(2026, 10, 27);

String _jwt(String sub, {String role = 'authenticated', int? expires}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({'sub': sub, 'role': role, 'exp': expires ?? _now.millisecondsSinceEpoch ~/ 1000 + 3600})}.signature';
}

Map<String, Object> _payload({
  String userId = _userA,
  String? token,
  String refreshToken = 'refresh-one',
}) => {
  'user': {'id': userId},
  'access_token': token ?? _jwt(userId),
  'refresh_token': refreshToken,
};

void main() {
  test('accepts a well-formed signed-identity refresh response', () {
    final parsed = r51ReadCredentials(_payload(), now: _now);
    expect(parsed.userId, _userA);
    expect(parsed.refreshToken, 'refresh-one');
  });

  test('rejects missing credentials without exposing their values', () {
    expect(
      () => r51ReadCredentials({
        'user': {'id': _userA},
        'access_token': _jwt(_userA),
      }, now: _now),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects token subject differing from response user', () {
    expect(
      () => r51ReadCredentials(_payload(token: _jwt(_userB)), now: _now),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects an expired access token', () {
    final expired = _now.millisecondsSinceEpoch ~/ 1000 - 1;
    expect(
      () => r51ReadCredentials(
        _payload(token: _jwt(_userA, expires: expired)),
        now: _now,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects a non-authenticated JWT role', () {
    expect(
      () => r51ReadCredentials(
        _payload(token: _jwt(_userA, role: 'service_role')),
        now: _now,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('valid renewal requires same identity and new refresh token', () {
    final original = r51ReadCredentials(_payload(), now: _now);
    final renewed = r51ReadCredentials(
      _payload(refreshToken: 'refresh-two'),
      now: _now,
    );
    expect(() => r51VerifyRotation(original, renewed), returnsNormally);
    expect(
      () => r51VerifyRotation(original, original),
      throwsA(isA<FormatException>()),
    );
    final wrongUser = r51ReadCredentials(
      _payload(userId: _userB, refreshToken: 'refresh-three'),
      now: _now,
    );
    expect(
      () => r51VerifyRotation(original, wrongUser),
      throwsA(isA<FormatException>()),
    );
  });

  test('server membership must match exactly one active role and company', () {
    final own = <Map<String, dynamic>>[
      {'company_id': _companyA, 'role': 'viewer', 'is_active': true},
    ];

    expect(
      r51HasExpectedMembership(own, companyId: _companyA, role: 'viewer'),
      isTrue,
    );

    expect(
      r51HasExpectedMembership(
        [own.single, own.single],
        companyId: _companyA,
        role: 'viewer',
      ),
      isFalse,
    );

    for (final invalid in [
      <Map<String, dynamic>>[],
      <Map<String, dynamic>>[
        {'company_id': _companyA, 'role': 'owner', 'is_active': true},
      ],
      <Map<String, dynamic>>[
        {'company_id': _companyA, 'role': 'viewer', 'is_active': false},
      ],
    ]) {
      expect(
        r51HasExpectedMembership(invalid, companyId: _companyA, role: 'viewer'),
        isFalse,
      );
    }
  });
}
