import 'package:test/test.dart';

import '../../../scripts/security/issue_317_r44_broadcast_observation.dart';
import '../../../scripts/security/issue_317_r44_dev_test_client.dart';
import '../../../scripts/security/verify_issue_317_r44_signed_jwt_write_boundaries.dart';

void main() {
  group('R4.4 signed-JWT direct write boundaries', () {
    test('only an explicit permission-denied SQLSTATE is a PASS', () {
      expect(
        r44DeniedDirectInsert(const R44Reply(403, {'code': '42501'})),
        isTrue,
      );
      for (final reply in [
        const R44Reply(201, null),
        const R44Reply(400, {'code': '23502'}),
        const R44Reply(403, {'code': '23514'}),
        const R44Reply(401, {'code': 'PGRST301'}),
        const R44Reply(500, {'code': '42501'}),
      ]) {
        expect(r44DeniedDirectInsert(reply), isFalse);
      }
    });

    test(
      'direct insert payload cannot satisfy NOT NULL settlement columns',
      () {
        const companyId = '041a7fc8-3593-41f2-b00f-99643277b18f';
        expect(r44MalformedInsert(companyId), {'company_id': companyId});
      },
    );
  });

  group('R4.4 private Broadcast forgery response', () {
    const topic =
        'realtime:horus:company:041a7fc8-3593-41f2-b00f-99643277b18f:driver_settlements';

    Map<String, Object?> reply(String status, String reason) => {
      'topic': topic,
      'event': 'phx_reply',
      'ref': '2',
      'payload': {
        'status': status,
        'response': {'reason': reason},
      },
    };

    test('requires explicit permission-based send rejection', () {
      expect(
        r44SenderAckFromFrame(
          reply('error', 'Unauthorized'),
          topic: topic,
          ref: '2',
        ),
        R44SenderAck.explicitlyDenied,
      );
      expect(
        r44SenderAckFromFrame(
          reply('error', 'rate limit exceeded'),
          topic: topic,
          ref: '2',
        ),
        R44SenderAck.unrelatedError,
      );
      expect(
        r44SenderAckFromFrame(reply('ok', ''), topic: topic, ref: '2'),
        R44SenderAck.accepted,
      );
    });

    test(
      'unrelated Phoenix replies and invalid payload never count as PASS',
      () {
        expect(
          r44SenderAckFromFrame(
            reply('error', 'Unauthorized'),
            topic: topic,
            ref: '1',
          ),
          isNull,
        );
        expect(
          r44SenderAckFromFrame('not-json', topic: topic, ref: '2'),
          isNull,
        );
      },
    );

    test('forged event contains only safe invalidation metadata', () {
      const companyId = '041a7fc8-3593-41f2-b00f-99643277b18f';
      final frame = r44ForgedBroadcast(topic, companyId);
      expect(frame['event'], 'broadcast');
      final payload = frame['payload']! as Map;
      expect(payload['event'], 'changed');
      expect(payload['payload'], {
        'company_id': companyId,
        'resource': 'driver_settlements',
        'qa_probe': 'r44_client_forgery_attempt',
      });
    });
  });
  group('R4.4 silent RLS Broadcast delivery observation', () {
    const topic =
        'realtime:horus:company:041a7fc8-3593-41f2-b00f-99643277b18f:driver_settlements';
    const marker = 'unique-qa-attempt-1';

    test('only matching marker from a subscribed topic indicates delivery', () {
      final envelope = r44ForgedBroadcast(
        topic,
        '041a7fc8-3593-41f2-b00f-99643277b18f',
        marker: marker,
      );
      expect(r44IsForgedEvent(envelope, topic: topic, marker: marker), isTrue);
      expect(
        r44IsForgedEvent(envelope, topic: topic, marker: 'other-attempt'),
        isFalse,
      );
      expect(
        r44IsForgedEvent(envelope, topic: 'realtime:other', marker: marker),
        isFalse,
      );
    });

    test('positive heartbeat confirms the receiving WebSocket is alive', () {
      final heartbeat = {
        'topic': 'phoenix',
        'event': 'phx_reply',
        'ref': '3',
        'payload': {'status': 'ok'},
      };
      expect(r44IsObserverHeartbeat(heartbeat, ref: '3'), isTrue);
      expect(r44IsObserverHeartbeat(heartbeat, ref: '4'), isFalse);
      expect(r44IsObserverHeartbeat({}, ref: '3'), isFalse);
    });

    test(
      'socket close or system failure cannot be treated as silent denial',
      () {
        expect(
          r44IsChannelTerminated({
            'topic': topic,
            'event': 'phx_close',
          }, topic: topic),
          isTrue,
        );
        expect(
          r44IsChannelTerminated({
            'topic': topic,
            'event': 'system',
            'payload': {'status': 'error'},
          }, topic: topic),
          isTrue,
        );
        expect(
          r44IsChannelTerminated({
            'topic': topic,
            'event': 'system',
            'payload': {'status': 'ok'},
          }, topic: topic),
          isFalse,
        );
      },
    );

    test('silent no-delivery is distinct from explicit rejection', () {
      expect(
        r44EvaluateBroadcast(
          sender: R44SenderAck.silent,
          forgedEventObserved: false,
          observerHeartbeatOk: true,
          fullObservationWindow: true,
          observerDisconnected: false,
        ),
        R44BroadcastOutcome.noDeliveryObserved,
      );
      expect(
        r44EvaluateBroadcast(
          sender: R44SenderAck.explicitlyDenied,
          forgedEventObserved: false,
          observerHeartbeatOk: true,
          fullObservationWindow: false,
          observerDisconnected: false,
        ),
        R44BroadcastOutcome.explicitlyDenied,
      );
    });

    test('delivered or acknowledged forgery always fails', () {
      for (final sender in R44SenderAck.values) {
        expect(
          r44EvaluateBroadcast(
            sender: sender,
            forgedEventObserved: true,
            observerHeartbeatOk: true,
            fullObservationWindow: true,
            observerDisconnected: false,
          ),
          R44BroadcastOutcome.delivered,
        );
      }
      expect(
        r44EvaluateBroadcast(
          sender: R44SenderAck.accepted,
          forgedEventObserved: false,
          observerHeartbeatOk: true,
          fullObservationWindow: true,
          observerDisconnected: false,
        ),
        R44BroadcastOutcome.delivered,
      );
    });

    test('disconnection or unrelated errors never pass as RLS denial', () {
      for (final sender in [R44SenderAck.silent, R44SenderAck.unrelatedError]) {
        expect(
          r44EvaluateBroadcast(
            sender: sender,
            forgedEventObserved: false,
            observerHeartbeatOk: false,
            fullObservationWindow: true,
            observerDisconnected: false,
          ),
          R44BroadcastOutcome.inconclusive,
        );
        expect(
          r44EvaluateBroadcast(
            sender: sender,
            forgedEventObserved: false,
            observerHeartbeatOk: true,
            fullObservationWindow: true,
            observerDisconnected: true,
          ),
          R44BroadcastOutcome.inconclusive,
        );
      }
      expect(
        r44EvaluateBroadcast(
          sender: R44SenderAck.unrelatedError,
          forgedEventObserved: false,
          observerHeartbeatOk: true,
          fullObservationWindow: true,
          observerDisconnected: false,
        ),
        R44BroadcastOutcome.inconclusive,
      );
    });
  });
}
