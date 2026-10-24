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
import 'issue_317_r44_broadcast_observation.dart';
import 'issue_317_r44_dev_test_client.dart';

// A permission-denied SQLSTATE, not a payload-validation error, is required.
bool r44DeniedDirectInsert(R44Reply reply) =>
    !reply.ok &&
    (reply.status == 401 || reply.status == 403) &&
    reply.sqlState == '42501';

Map<String, Object?> r44MalformedInsert(String companyId) => {
  // Both settlement tables have other mandatory NOT NULL columns. Even if
  // authorization is accidentally broadened, this payload cannot commit.
  'company_id': companyId,
};

Map<String, Object?> r44ForgedBroadcast(
  String topic,
  String companyId, {
  String marker = 'r44_client_forgery_attempt',
  String resource = 'driver_settlements',
}) => {
  'topic': topic,
  'event': 'broadcast',
  'join_ref': '1',
  'ref': '2',
  'payload': {
    'type': 'broadcast',
    'event': 'changed',
    'payload': {
      'company_id': companyId,
      'resource': resource,
      'qa_probe': marker,
    },
  },
};

// Unlike direct table writes, Realtime RLS-denied Broadcasts are silently
// dropped by Supabase. This uses an independent receiving socket and a
// heartbeat. 'No delivery observed' is distinct from an explicit denial.
Future<R44BroadcastOutcome> r44TryForgedBroadcast(
  R44DevConfig config,
  R44Session session, {
  String resource = 'driver_settlements',
}) async {
  final topic = financeTopic(session.companyId, resource);
  WebSocket? senderSocket;
  WebSocket? observerSocket;
  StreamIterator<dynamic>? senderMessages;
  StreamIterator<dynamic>? observerMessages;
  try {
    observerSocket = await WebSocket.connect(
      config.websocketAddress().toString(),
    ).timeout(r44NetworkTimeout);
    observerMessages = StreamIterator<dynamic>(observerSocket);
    senderSocket = await WebSocket.connect(
      config.websocketAddress().toString(),
    ).timeout(r44NetworkTimeout);
    senderMessages = StreamIterator<dynamic>(senderSocket);

    final observerJoin = joinFinanceTopic(
      topic: topic,
      ref: '1',
      jwt: session.jwt,
    );
    observerSocket.add(jsonEncode(observerJoin));
    if (await _waitForJoin(observerMessages, topic) !=
        RealtimeJoinVerdict.allowed) {
      return R44BroadcastOutcome.inconclusive;
    }

    final senderJoin = joinFinanceTopic(
      topic: topic,
      ref: '1',
      jwt: session.jwt,
    );
    (senderJoin['payload'] as Map)['config'] = {
      'private': true,
      'broadcast': {'self': false, 'ack': true},
      'presence': {'enabled': false},
      'postgres_changes': <Object>[],
    };
    senderSocket.add(jsonEncode(senderJoin));
    if (await _waitForJoin(senderMessages, topic) !=
        RealtimeJoinVerdict.allowed) {
      return R44BroadcastOutcome.inconclusive;
    }

    final marker = 'r44_${DateTime.now().microsecondsSinceEpoch}';
    senderSocket.add(jsonEncode(r44ForgedBroadcast(
      topic,
      session.companyId,
      marker: marker,
      resource: resource,
    )));
    // A second WebSocket tests whether the forged message was actually
    // delivered. Heartbeat after sending confirms the observer remains live.
    observerSocket.add(jsonEncode({
      'topic': 'phoenix',
      'event': 'heartbeat',
      'ref': '3',
      'payload': <String, Object?>{},
    }));

    const observationWindow = Duration(seconds: 5);
    final results = await Future.wait<Object>([
      _waitForSend(senderMessages, topic, observationWindow),
      _observeForgery(observerMessages, topic, marker, observationWindow),
    ]);
    final sender = results[0] as R44SenderAck;
    final observer = results[1] as R44ObserverWindow;
    return r44EvaluateBroadcast(
      sender: sender,
      forgedEventObserved: observer.forgedEvent,
      observerHeartbeatOk: observer.heartbeatOk,
      fullObservationWindow: observer.windowComplete,
      observerDisconnected: observer.disconnected,
    );
  } catch (_) {
    return R44BroadcastOutcome.inconclusive;
  } finally {
    try {
      await senderMessages?.cancel().timeout(const Duration(seconds: 2));
      await observerMessages?.cancel().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Network shutdown cannot count as an authorization PASS.
    }
    try {
      await senderSocket?.close().timeout(const Duration(seconds: 2));
      await observerSocket?.close().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Do not leak network failures or authorization headers.
    }
  }
}

final class R44ObserverWindow {
  final bool heartbeatOk;
  final bool forgedEvent;
  final bool windowComplete;
  final bool disconnected;

  const R44ObserverWindow({
    required this.heartbeatOk,
    required this.forgedEvent,
    required this.windowComplete,
    required this.disconnected,
  });
}

Future<R44ObserverWindow> _observeForgery(
  StreamIterator<dynamic> messages,
  String topic,
  String marker,
  Duration window,
) async {
  final deadline = DateTime.now().add(window);
  var heartbeatOk = false;
  while (DateTime.now().isBefore(deadline)) {
    final remaining = deadline.difference(DateTime.now());
    try {
      if (!await messages.moveNext().timeout(remaining)) {
        return R44ObserverWindow(
          heartbeatOk: heartbeatOk,
          forgedEvent: false,
          windowComplete: false,
          disconnected: true,
        );
      }
    } on TimeoutException {
      return R44ObserverWindow(
        heartbeatOk: heartbeatOk,
        forgedEvent: false,
        windowComplete: true,
        disconnected: false,
      );
    }
    final frame = messages.current;
    if (r44IsForgedEvent(frame, topic: topic, marker: marker)) {
      return R44ObserverWindow(
        heartbeatOk: heartbeatOk,
        forgedEvent: true,
        windowComplete: false,
        disconnected: false,
      );
    }
    if (r44IsObserverHeartbeat(frame, ref: '3')) heartbeatOk = true;
    if (r44IsChannelTerminated(frame, topic: topic)) {
      return R44ObserverWindow(
        heartbeatOk: heartbeatOk,
        forgedEvent: false,
        windowComplete: false,
        disconnected: true,
      );
    }
  }
  return R44ObserverWindow(
    heartbeatOk: heartbeatOk,
    forgedEvent: false,
    windowComplete: true,
    disconnected: false,
  );
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

Future<R44SenderAck> _waitForSend(
  StreamIterator<dynamic> messages,
  String topic,
  Duration window,
) async {
  final deadline = DateTime.now().add(window);
  while (DateTime.now().isBefore(deadline)) {
    final remaining = deadline.difference(DateTime.now());
    try {
      if (!await messages.moveNext().timeout(remaining)) {
        return R44SenderAck.unrelatedError;
      }
    } on TimeoutException {
      return R44SenderAck.silent;
    }
    if (r44IsChannelTerminated(messages.current, topic: topic)) {
      return R44SenderAck.unrelatedError;
    }
    final verdict = r44SenderAckFromFrame(
      messages.current,
      topic: topic,
      ref: '2',
    );
    if (verdict != null) return verdict;
  }
  return R44SenderAck.silent;
}

Future<void> main(List<String> args) async {
  final roles = args.where((value) => value.startsWith('--role=')).toList();
  final modes = args.where((value) =>
      value == '--preflight' || value == '--execute').toList();
  final broadcastOnly = args.contains('--broadcast-only');
  if (args.length != (broadcastOnly ? 3 : 2) ||
      roles.length != 1 ||
      modes.length != 1 ||
      (broadcastOnly && modes.single != '--execute')) {
    stderr.writeln(
      'Usage: --preflight|--execute --role=owner|admin|accountant '
      '[--broadcast-only for --execute]',
    );
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
    var checks = 1; // Broadcast probe always runs.
    if (!broadcastOnly) {
      for (final table in ['driver_settlements', 'driver_settlement_items']) {
        checks++;
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
    }

    final broadcast = await r44TryForgedBroadcast(config, session);
    final pass = {
      R44BroadcastOutcome.explicitlyDenied,
      R44BroadcastOutcome.noDeliveryObserved,
    }.contains(broadcast);
    switch (broadcast) {
      case R44BroadcastOutcome.explicitlyDenied:
        stdout.writeln('PASS  private Broadcast explicitly denied');
      case R44BroadcastOutcome.noDeliveryObserved:
        stdout.writeln(
          'PASS  no forged Broadcast observed on live receiver '
          '(also verify RLS write policies separately)',
        );
      case R44BroadcastOutcome.delivered:
        stdout.writeln('FAIL  forged Broadcast accepted or delivered');
      case R44BroadcastOutcome.inconclusive:
        stdout.writeln('FAIL  Broadcast probe inconclusive; no security PASS');
    }
    if (!pass) failures++;
    stdout.writeln('SUMMARY: ${checks - failures} PASS / $failures FAIL');
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
