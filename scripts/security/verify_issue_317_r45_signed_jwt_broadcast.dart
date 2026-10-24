// Issue #317 R4.5 — Development-only, signed-JWT private Invoice Broadcast
// forgery probe. Reuses the independently observed R4.4 security transport.
// Sends an invalidation marker ONLY: never creates/modifies an invoice.
// Usage:
//   dart run scripts/security/verify_issue_317_r45_signed_jwt_broadcast.dart --preflight --role=admin
//   dart run scripts/security/verify_issue_317_r45_signed_jwt_broadcast.dart --execute --role=admin

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
    stderr.writeln(
      'Usage: --preflight|--execute --role=owner|admin|accountant',
    );
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
      stdout.writeln('PASS  R4.5 Development-only broadcast preflight.');
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

    final outcome = await r44TryForgedBroadcast(
      config,
      session,
      resource: 'invoices',
    );
    switch (outcome) {
      case R44BroadcastOutcome.explicitlyDenied:
        stdout.writeln('PASS  invoice Broadcast explicitly denied');
      case R44BroadcastOutcome.noDeliveryObserved:
        stdout.writeln(
          'PASS  no forged Invoice Broadcast delivered to independent receiver',
        );
      case R44BroadcastOutcome.delivered:
        stdout.writeln('FAIL  forged Invoice Broadcast delivered');
        exitCode = 1;
      case R44BroadcastOutcome.inconclusive:
        stdout.writeln('FAIL  inconclusive — no authorization PASS');
        exitCode = 1;
    }
    stdout.writeln('Check R4.5 realtime.messages INSERT grants and policies separately.');
  } catch (_) {
    stderr.writeln(
      'BLOCKED — invalid Development configuration, role or connection. '
      'Secrets suppressed; no Invoice changes submitted.',
    );
    exitCode = 1;
  } finally {
    client?.close();
  }
}
