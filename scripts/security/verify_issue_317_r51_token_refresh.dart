// Issue #317 R5.1 — Development-only live JWT refresh contract.
// Run: dart run scripts/security/verify_issue_317_r51_token_refresh.dart --preflight
// Run: dart run scripts/security/verify_issue_317_r51_token_refresh.dart --execute
//
// Requires the same Development-only env as the existing Issue #317 signed-JWT
// suite, plus an interactive Viewer test account. Does NOT touch the Windows
// app's own session. No database writes, migrations or Production access.
// Credentials, JWTs, refresh tokens, identities and raw errors never print.

import 'dart:io';

import 'issue_317_r44_dev_test_client.dart';
import 'issue_317_r51_token_refresh_contract.dart';

final class _Verifier {
  final R44DevClient _client;
  final R44DevConfig _config;
  int _passed = 0;

  _Verifier(this._client, this._config);

  void pass(String label) {
    _passed++;
    stdout.writeln('PASS  $label');
  }

  Future<R51RenewedCredentials> signIn() async {
    final email = r44Prompt('Viewer Development test email: ');
    if (email.isEmpty) {
      throw const FormatException('Viewer test account required.');
    }
    final password = r44Password();
    final response = await _client.request(
      'POST',
      '/auth/v1/token',
      query: {'grant_type': 'password'},
      data: {'email': email, 'password': password},
    );
    if (!response.ok) {
      throw const FormatException('Development Viewer sign-in failed.');
    }
    final session = r51ReadCredentials(response.body);
    pass('Development Viewer identity authenticated');
    return session;
  }

  Future<R51RenewedCredentials> refresh(R51RenewedCredentials previous) async {
    final response = await _client.request(
      'POST',
      '/auth/v1/token',
      query: {'grant_type': 'refresh_token'},
      data: {'refresh_token': previous.refreshToken},
    );
    if (!response.ok) {
      throw const FormatException('Development session renewal refused.');
    }
    final renewed = r51ReadCredentials(response.body);
    r51VerifyRotation(previous, renewed);
    pass('Server rotated refresh token with unchanged signed identity');
    return renewed;
  }

  Future<void> verifyTenantAccess(
    R51RenewedCredentials session, {
    required String phase,
  }) async {
    final own = await _client.request(
      'GET',
      '/rest/v1/company_users',
      jwt: session.accessToken,
      query: {
        'select': 'company_id,role,is_active',
        'user_id': 'eq.${session.userId}',
        'company_id': 'eq.${_config.companyA}',
      },
    );
    if (!r51HasExpectedMembership(
      own.rows,
      companyId: _config.companyA,
      role: 'viewer',
    )) {
      throw const FormatException('Development Viewer membership invalid.');
    }
    pass('$phase own Viewer membership readable through RLS');

    final foreign = await _client.request(
      'GET',
      '/rest/v1/company_users',
      jwt: session.accessToken,
      query: {
        'select': 'company_id',
        'company_id': 'eq.${_config.companyB}',
      },
    );
    if (foreign.rows.isNotEmpty) {
      throw const FormatException('Foreign tenant isolation invalid.');
    }
    pass('$phase foreign tenant membership denied through RLS');
  }

  void complete() {
    stdout.writeln('SUMMARY: $_passed PASS / 0 FAIL / 0 SKIP');
  }
}

Future<void> main(List<String> args) async {
  if (args.length != 1 ||
      (args.single != '--preflight' && args.single != '--execute')) {
    stderr.writeln('Usage: --preflight | --execute');
    exitCode = 64;
    return;
  }

  R44DevClient? client;
  try {
    // Existing strict host allowlist and publishable-only configuration.
    final config = R44DevConfig.fromEnvironment();
    if (args.single == '--preflight') {
      stdout.writeln('PASS  R5.1 Development-only token refresh preflight');
      return;
    }

    if (!stdin.hasTerminal) {
      throw const FormatException('Interactive Development terminal required.');
    }

    client = R44DevClient(config);
    final verifier = _Verifier(client, config);
    final initial = await verifier.signIn();
    await verifier.verifyTenantAccess(initial, phase: 'Before renewal');

    final renewed = await verifier.refresh(initial);
    await verifier.verifyTenantAccess(renewed, phase: 'After renewal');
    verifier.complete();
  } catch (_) {
    // Never print backend error bodies, user identifiers or credentials.
    stderr.writeln('FAIL  R5.1 Development session renewal contract');
    exitCode = 1;
  } finally {
    client?.close();
  }
}
