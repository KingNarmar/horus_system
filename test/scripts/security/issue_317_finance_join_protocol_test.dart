import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/realtime/data/constants/realtime_topics.dart';

import '../../../scripts/security/issue_317_finance_join_protocol.dart';

void main() {
  const company = '01020304-0506-0708-090a-0b0c0d0e0f10';
  const topic = 'realtime:horus:company:$company:expense_ledger';

  test('finance topics match app private broadcast resource names', () {
    expect(
      financeTopic(company, 'expense_ledger'),
      'realtime:${RealtimeTopics.expenseLedger(company)}',
    );
    expect(
      financeTopic(company, 'trip_expenses'),
      'realtime:${RealtimeTopics.tripExpenses(company)}',
    );
  });

  test('private join includes token only for authenticated user', () {
    final authorized = joinFinanceTopic(
      topic: topic,
      ref: '1',
      jwt: 'signed-token-fixture',
    );
    expect(authorized['event'], 'phx_join');
    expect(authorized['topic'], topic);
    expect(authorized['join_ref'], '1');
    final payload = authorized['payload'] as Map;
    expect(payload['access_token'], 'signed-token-fixture');
    final config = payload['config'] as Map;
    expect(config['private'], isTrue);
    expect(config['postgres_changes'], isEmpty);
    expect(config['broadcast'], {'self': false, 'ack': false});

    final anonymous = joinFinanceTopic(topic: topic, ref: '1');
    expect((anonymous['payload'] as Map).containsKey('access_token'), isFalse);
  });

  test('join success requires matching reference and topic', () {
    final success = {
      'topic': topic,
      'event': 'phx_reply',
      'ref': '1',
      'payload': {'status': 'ok', 'response': <String, Object>{}},
    };
    expect(
      parseFinanceJoinResult(jsonEncode(success), topic: topic, ref: '1'),
      RealtimeJoinVerdict.allowed,
    );
    expect(
      parseFinanceJoinResult(success, topic: 'realtime:another', ref: '1'),
      isNull,
    );
    expect(parseFinanceJoinResult(success, topic: topic, ref: '2'), isNull);
  });

  test('explicit access rejection is denied, not a socket timeout', () {
    final denied = {
      'topic': topic,
      'event': 'phx_reply',
      'ref': '1',
      'payload': {
        'status': 'error',
        'response': {'reason': 'Unauthorized: permission denied'},
      },
    };
    expect(
      parseFinanceJoinResult(denied, topic: topic, ref: '1'),
      RealtimeJoinVerdict.denied,
    );
  });

  test('transient rate limit and database errors never pass as denials', () {
    for (final reason in [
      'ClientJoinRateLimitReached: slow down',
      'DatabaseLackOfConnections: retry later',
      'RealtimeRestarting: retry',
    ]) {
      expect(
        parseFinanceJoinResult(
          {
            'topic': topic,
            'event': 'phx_reply',
            'ref': '1',
            'payload': {
              'status': 'error',
              'response': {'reason': reason},
            },
          },
          topic: topic,
          ref: '1',
        ),
        RealtimeJoinVerdict.inconclusive,
      );
    }
    expect(
      parseFinanceJoinResult('not-json', topic: topic, ref: '1'),
      RealtimeJoinVerdict.inconclusive,
    );
  });
}
