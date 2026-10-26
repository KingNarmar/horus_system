// Issue #317 R4.6 — Development-only, signed-JWT Payments Broadcast forgery
// and direct-write negative probe. Never creates a legitimate payment.
// Usage: dart run scripts/security/verify_issue_317_r46_signed_jwt_broadcast.dart --execute --role=owner
import 'dart:io';

import 'issue_317_r44_broadcast_observation.dart';
import 'issue_317_r44_dev_test_client.dart';
import 'verify_issue_317_r44_signed_jwt_write_boundaries.dart';

const _allowedRoles = {'owner', 'admin', 'accountant'};

Future<void> main(List<String> args) async {
  final modes = args.where(
    (arg) => arg == '--preflight' || arg == '--execute',
  ).toList();
  final roles = args.where((arg) => arg.startsWith('--role=')).toList();
  if (args.length != 2 || modes.length != 1 || roles.length != 1) {
    stderr.writeln('Usage: --preflight|--execute --role=owner|admin|accountant');
    exitCode = 64;
    return;
  }
  final role = roles.single.substring('--role='.length);
  if (!_allowedRoles.contains(role)) {
    stderr.writeln('Finance Development role required.');
    exitCode = 64;
    return;
  }

  R44DevClient? client;
  try {
    final config = R44DevConfig.fromEnvironment();
    if (!stdin.hasTerminal) {
      throw StateError('Interactive Development terminal required.');
    }
    if (modes.single == '--preflight') {
      stdout.writeln('PASS  R4.6 Development-only broadcast preflight.');
      return;
    }

    client = R44DevClient(config);
    final email = r44Prompt('$role Development test email: ');
    if (email.isEmpty) throw StateError('Role test account required.');
    final session = await client.loginForRole(
      role: role,
      email: email,
      password: r44Password(),
    );

    var failed = 0;
    final directWrite = await client.request(
      'POST',
      '/rest/v1/payments',
      jwt: session.jwt,
      data: {'company_id': session.companyId},
    );
    if (r44DeniedDirectInsert(directWrite)) {
      stdout.writeln('PASS  direct Payments INSERT refused');
    } else {
      stdout.writeln('FAIL  direct Payments INSERT not permission-denied');
      failed++;
    }

    final outcome = await r44TryForgedBroadcast(
      config,
      session,
      resource: 'payments',
    );
    switch (outcome) {
      case R44BroadcastOutcome.explicitlyDenied:
        stdout.writeln('PASS  Payments Broadcast explicitly denied');
      case R44BroadcastOutcome.noDeliveryObserved:
        stdout.writeln(
          'PASS  no forged Payments Broadcast delivered to receiver',
        );
      case R44BroadcastOutcome.delivered:
        stdout.writeln('FAIL  forged Payments Broadcast delivered');
        failed++;
      case R44BroadcastOutcome.inconclusive:
        stdout.writeln('FAIL  inconclusive — no authorization PASS');
        failed++;
    }
    stdout.writeln('SUMMARY: ${2 - failed} PASS / $failed FAIL');
    if (failed > 0) exitCode = 1;
  } catch (_) {
    stderr.writeln(
      'BLOCKED — invalid Development configuration, role or connection. '
      'Secrets suppressed; no payment registered.',
    );
    exitCode = 1;
  } finally {
    client?.close();
  }
}
