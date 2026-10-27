import 'dart:async';

import 'package:horus_system/core/realtime/data/datasources/realtime_channel_gateway.dart';
import 'package:horus_system/core/realtime/data/models/realtime_change_signal.dart';
import 'package:horus_system/features/company/data/constants/company_membership_realtime_topics.dart';
import 'package:horus_system/features/company/data/datasources/company_membership_changes_remote_data_source.dart';
import 'package:horus_system/features/company/data/mappers/company_membership_change_decoder.dart';
import 'package:test/test.dart';

void main() {
  test('only the signed-in user may start the private membership channel',
      () async {
    final gateway = _FakeGateway();
    final source =
        SupabaseCompanyMembershipChangesRemoteDataSource.withGateway(
      gateway,
      () => 'user-a',
    );

    final signals = await source.watchChanges(userId: 'user-b').toList();
    expect(signals, [RealtimeChangeSignal.unavailable]);
    expect(gateway.subscribedTopic, isNull);
  });

  test('own membership events invalidate; foreign or malformed events do not',
      () async {
    final gateway = _FakeGateway();
    final source =
        SupabaseCompanyMembershipChangesRemoteDataSource.withGateway(
      gateway,
      () => 'user-a',
    );
    final signals = <RealtimeChangeSignal>[];
    final subscription =
        source.watchChanges(userId: 'user-a').listen(signals.add);

    await Future<void>.delayed(Duration.zero);
    expect(gateway.subscribedTopic,
        CompanyMembershipRealtimeTopics.userMemberships('user-a'));

    gateway.status!(RealtimeChannelJoinStatus.subscribed);
    gateway.message!({
      'payload': {'user_id': 'user-b', 'resource': 'membership'},
    });
    gateway.message!({'payload': {'user_id': 'user-a', 'resource': 'finance'}});
    gateway.message!({
      'payload': {'user_id': 'user-a', 'resource': 'membership'},
    });
    await Future<void>.delayed(Duration.zero);

    expect(signals, [
      RealtimeChangeSignal.subscribed,
      RealtimeChangeSignal.changed,
    ]);
    await subscription.cancel();
    expect(gateway.removes, 1);
  });

  test('invalid envelope never authorizes a membership change', () {
    expect(CompanyMembershipChangeDecoder.isForUser(
      {'payload': {'user_id': 'user-b', 'resource': 'membership'}},
      userId: 'user-a',
    ), isFalse);
    expect(CompanyMembershipChangeDecoder.isForUser(
      {'user_id': 'user-a', 'resource': 'membership'},
      userId: 'user-a',
    ), isFalse);
  });
}

final class _FakeGateway implements RealtimeChannelGateway {
  String? subscribedTopic;
  void Function(Map<String, dynamic>)? message;
  void Function(RealtimeChannelJoinStatus)? status;
  int removes = 0;

  @override
  String? get accessToken => 'test-jwt';

  @override
  Future<void> authenticate(String token) async {}

  @override
  RealtimeChannelHandle subscribe({
    required String topic,
    required String event,
    required void Function(Map<String, dynamic>) onMessage,
    required void Function(RealtimeChannelJoinStatus) onStatus,
  }) {
    subscribedTopic = topic;
    message = onMessage;
    status = onStatus;
    return _FakeHandle();
  }

  @override
  Future<void> remove(RealtimeChannelHandle handle) async {
    removes++;
  }
}

final class _FakeHandle implements RealtimeChannelHandle {}
