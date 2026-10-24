import 'package:test/test.dart';

import '../../../scripts/security/issue_317_r44_dev_test_client.dart';
import '../../../scripts/security/verify_issue_317_r44_signed_jwt_write_boundaries.dart';

void main() {
  group('R4.4 signed-JWT direct write boundaries', () {
    test('only an explicit permission-denied SQLSTATE is a PASS', () {
      expect(
        r44DeniedDirectInsert(
          const R44Reply(403, {'code': '42501'}),
        ),
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

    test('direct insert payload cannot satisfy NOT NULL settlement columns', () {
      const companyId = '041a7fc8-3593-41f2-b00f-99643277b18f';
      expect(r44MalformedInsert(companyId), {'company_id': companyId});
    });
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
        r44SendReplyVerdict(
          reply('error', 'Unauthorized'),
          topic: topic,
          ref: '2',
        ),
        R44SendVerdict.denied,
      );
      expect(
        r44SendReplyVerdict(
          reply('error', 'rate limit exceeded'),
          topic: topic,
          ref: '2',
        ),
        R44SendVerdict.inconclusive,
      );
      expect(
        r44SendReplyVerdict(reply('ok', ''), topic: topic, ref: '2'),
        R44SendVerdict.allowed,
      );
    });

    test('unrelated Phoenix replies and invalid payload never count as PASS', () {
      expect(
        r44SendReplyVerdict(
          reply('error', 'Unauthorized'),
          topic: topic,
          ref: '1',
        ),
        isNull,
      );
      expect(
        r44SendReplyVerdict('not-json', topic: topic, ref: '2'),
        R44SendVerdict.inconclusive,
      );
    });

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
}
