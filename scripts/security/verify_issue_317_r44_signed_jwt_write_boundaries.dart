// Issue #317 R4.4: Development-only signed-JWT direct-write and Broadcast
// forgery checks. NEVER creates a valid settlement or business source row.
// A forged Broadcast, if a security regression exists, can cause refresh only.
//
// dart run scripts/security/verify_issue_317_r44_signed_jwt_write_boundaries.dart --preflight --role=admin
// dart run scripts/security/verify_issue_317_r44_signed_jwt_write_boundaries.dart --execute --role=admin

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'issue_317_finance_join_protocol.dart';
import 'issue_317_r44_dev_test_client.dart';

enum R44SendVerdict { denied, allowed, inconclusive }

bool r44DeniedDirectInsert(R44Reply reply) =>
    !reply.ok &&
    (reply.status == 401 || reply.status == 403) &&
    reply.sqlState == '42501';

R44SendVerdict? r44SendReplyVerdict(
  Object? message, {
  required String topic,
  required String ref,
}) {
  Object? decoded = message;
  try {
    if (message is String) decoded = jsonDecode(message);
  } on FormatException {
    return R44SendVerdict.inconclusive;
  }
  if (decoded is! Map ||
      decoded['topic'] != topic ||
      decoded['event'] != 'phx_reply' ||
      decoded['ref'] != ref) {
    return null;
  }
  final payload = decoded['payload'];
  if (payload is! Map) return R44SendVerdict.inconclusive;
  if (payload['status'] == 'ok') return R44SendVerdict.allowed;
  if (payload['status'] != 'error') return R44SendVerdict.inconclusive;
  final response = payload['response'];
  if (response is! Map) return R44SendVerdict.inconclusive;
  final reason = (response['reason'] ?? response['message'])?.toString();
  if (reason == null) return R44SendVerdict.inconclusive;
  final value = reason.toLowerCase();
  return [
    'unauthorized',
    'not authorized',
    'forbidden',
    'permission',
    'access denied',
    'row-level security',
    'rls',
  ].any(value.contains)
      ? R44SendVerdict.denied
      : R44SendVerdict.inconclusive;
}

Map<String, Object?> r44MalformedInsert(String companyId) => {
  // Both settlement tables have other mandatory NOT NULL columns. Even if
  // authorization is accidentally broadened, this payload cannot commit.
  'company_id': companyId,
};

Map<String, Object?> r44ForgedBroadcast(String topic, String companyId) => {
  'topic': topic,
  'event': 'broadcast',
  'join_ref': '1',
  'ref': '2',
  'payload': {
    'type': 'broadcast',
    'event': 'changed',
    'payload': {
      'company_id': companyId,
      'resource': 'driver_settlements',
      'qa_probe': 'r44_client_forgery_attempt',
    },
  },
};

Future<R44SendVerdict> r44TryForgedBroadcast(
  R44DevConfig config,
  R44Session session,
) async {
  final topic = financeTopic(session.companyId, 'driver_settlements');
  WebSocket? socket;
  StreamIterator<dynamic>? messages;
  try {
    socket = await WebSocket.connect(
      config.websocketAddress().toString(),
    ).timeout(r44NetworkTimeout);
    messages = StreamIterator<dynamic>(socket);
    final join = joinFinanceTopic(
      topic: topic,
      ref: '1',
      jwt: session.jwt,
    );
    // Wait for an explicit server denial instead of relying on a silent send.
    (join['payload'] as Map)['config'] = {
      'private': true,
      'broadcast': {'self': true, 'ack': true},
      'presence': {'enabled': false},
      'postgres_changes': <Object>[],
    };
    socket.add(jsonEncode(join));
    final joined = await _waitForJoin(messages, topic);
    if (joined != RealtimeJoinVerdict.allowed) {
      return R44SendVerdict.inconclusive;
    }
    socket.add(jsonEncode(r44ForgedBroadcast(
      topic,
      session.companyId,
    )));
    return await _waitForSend(messages, topic);
  } catch (_) {
    return R44SendVerdict.inconclusive;
  } finally {
    try {
      await messages?.cancel().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Credentials and raw server errors are intentionally suppressed.
    }
    try {
      await socket?.close().timeout(const Duration(seconds: 2));
    } catch (_) {
      // A transport failure never counts as an authorization PASS.
    }
  }
}

Future<RealtimeJoinVerdict> _waitForJoin(
  StreamIterator<dynamic> messages,
  String topic,
) async {
  final deadline = DateTime.now().add(r44NetworkTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final remaining = deadline.difference(DateTime.now());
    if (!await messages.moveNext().timeout(remaining)) break;
    final verdict = parseFinanceJoinResult(
      messages.current,
      topic: topic,
      ref: '1',
    );
    if (verdict != null) return verdict;
  }
  return RealtimeJoinVerdict.inconclusive;
}

Future<R44SendVerdict> _waitForSend(
  StreamIterator<dynamic> messages,
  String topic,
) async {
  final deadline = DateTime.now().add(r44NetworkTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final remaining = deadline.difference(DateTime.now());
    if (!await messages.moveNext().timeout(remaining)) break;
    final verdict = r44SendReplyVerdict(
      messages.current,
      topic: topic,
      ref: '2',
    );
    if (verdict != null) return verdict;
    // Receiving the injected test event is proof that client forgery worked,
    // regardless of whether the acknowledgement subsequently fails.
    Object? payload = messages.current;
    try {
      if (payload is String) payload = jsonDecode(payload);
    } on FormatException {
      continue;
    }
    if (payload is Map &&
        payload['topic'] == topic &&
        payload['event'] == 'broadcast' &&
        payload['payload'] is Map &&
        (payload['payload'] as Map)['event'] == 'changed') {
      return R44SendVerdict.allowed;
    }
  }
  return R44SendVerdict.inconclusive;
}

Future<void> main(List<String> args) async {
  final roles = args.where((value) => value.startsWith('--role=')).toList();
  final modes = args.where((value) =>
      value == '--preflight' || value == '--execute').toList();
  if (args.length != 2 || roles.length != 1 || modes.length != 1) {
    stderr.writeln('Usage: --preflight|--execute --role=owner|admin|accountant');
    exitCode = 64;
    return;
  }
  final role = roles.single.substring('--role='.length);
  if (!{'owner', 'admin', 'accountant'}.contains(role)) {
    stderr.writeln('Only finance roles can run this security probe.');
    exitCode = 64;
    return;
  }
  R44DevClient? client;
  try {
    final config = R44DevConfig.fromEnvironment();
    if (!stdin.hasTerminal) throw StateError('Interactive console required.');
    if (modes.single == '--preflight') {
      stdout.writeln('PASS  Development-only signed-JWT boundary preflight.');
      return;
    }

    client = R44DevClient(config);
    final email = r44Prompt('$role Development test email: ');
    if (email.isEmpty) throw StateError('Test account required.');
    final session = await client.loginForRole(
      role: role,
      email: email,
      password: r44Password(),
    );
    var failures = 0;
    for (final table in ['driver_settlements', 'driver_settlement_items']) {
      final result = await client.request(
        'POST',
        '/rest/v1/$table',
        jwt: session.jwt,
        data: r44MalformedInsert(session.companyId),
      );
      final pass = r44DeniedDirectInsert(result);
      stdout.writeln(pass
          ? 'PASS  direct $table INSERT refused'
          : 'FAIL  direct $table INSERT was not permission-denied');
      if (!pass) failures++;
    }

    final broadcast = await r44TryForgedBroadcast(config, session);
    final pass = broadcast == R44SendVerdict.denied;
    stdout.writeln(pass
        ? 'PASS  client Broadcast forgery refused'
        : 'FAIL  Broadcast denial unverified (allowed or inconclusive)');
    if (!pass) failures++;
    stdout.writeln('SUMMARY: ' +
        (3 - failures).toString() +
        ' PASS / ' +
        failures.toString() +
        ' FAIL');
    if (failures > 0) exitCode = 1;
  } catch (_) {
    stderr.writeln(
      'BLOCKED — Development role, configuration or transport invalid. '
      'Secrets suppressed; no valid settlement submitted.',
    );
    exitCode = 1;
  } finally {
    client?.close();
  }
}
