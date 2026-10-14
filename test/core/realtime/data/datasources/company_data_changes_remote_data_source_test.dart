import 'dart:async';

import 'package:horus_system/core/realtime/data/constants/realtime_topics.dart';
import 'package:horus_system/core/realtime/data/datasources/company_data_changes_remote_data_source.dart';
import 'package:horus_system/core/realtime/data/datasources/realtime_channel_gateway.dart';
import 'package:horus_system/core/realtime/data/models/realtime_change_signal.dart';
import 'package:test/test.dart';

void main() {
  test(
    'private company subscription only accepts current-tenant changes',
    () async {
      final gateway = _FakeGateway();
      final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
        gateway,
      );
      final received = <RealtimeChangeSignal>[];
      final subscription = source
          .watchCustomers(companyId: 'company-a')
          .listen(received.add);
      await Future<void>.delayed(Duration.zero);

      expect(gateway.authTokens, ['development-test-token']);
      expect(gateway.channels, hasLength(1));
      final channel = gateway.channels.single;
      expect(channel.topic, RealtimeTopics.customers('company-a'));
      expect(channel.event, RealtimeTopics.customersChangedEvent);

      channel.onStatus(RealtimeChannelJoinStatus.subscribed);
      channel.onMessage({
        'payload': {'company_id': 'company-b', 'resource': 'customers'},
      });
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'customers'},
      });
      await Future<void>.delayed(Duration.zero);
      expect(received, [
        RealtimeChangeSignal.subscribed,
        RealtimeChangeSignal.changed,
      ]);

      await subscription.cancel();
      expect(gateway.removed, [channel]);
      channel.onStatus(RealtimeChannelJoinStatus.subscribed);
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'customers'},
      });
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(2));
    },
  );

  test(
    'cancel before asynchronous authentication never opens channel',
    () async {
      final gateway = _FakeGateway()..authBarrier = Completer<void>();
      final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
        gateway,
      );
      final subscription = source
          .watchCustomers(companyId: 'company-a')
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(gateway.authTokens, hasLength(1));

      await subscription.cancel();
      gateway.authBarrier!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(gateway.channels, isEmpty);
      expect(gateway.removed, isEmpty);
    },
  );

  test(
    'SDK error then subscribed rejoin requests authoritative refresh',
    () async {
      final gateway = _FakeGateway();
      final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
        gateway,
      );
      final received = <RealtimeChangeSignal>[];
      final subscription = source
          .watchCustomers(companyId: 'company-a')
          .listen(received.add);
      await Future<void>.delayed(Duration.zero);

      final channel = gateway.channels.single;
      channel.onStatus(RealtimeChannelJoinStatus.unavailable);
      channel.onStatus(RealtimeChannelJoinStatus.subscribed);
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'customers'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(received, [
        RealtimeChangeSignal.unavailable,
        RealtimeChangeSignal.subscribed,
        RealtimeChangeSignal.changed,
      ]);
      await subscription.cancel();
    },
  );

  test('unauthenticated session never subscribes', () async {
    final gateway = _FakeGateway()..accessToken = null;
    final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
      gateway,
    );
    final received = await source.watchCustomers(companyId: 'company-a').first;
    expect(received, RealtimeChangeSignal.unavailable);
    expect(gateway.channels, isEmpty);
  });

  test(
    'channel removal failure is propagated, never silently discarded',
    () async {
      final gateway = _FakeGateway()..failRemoval = true;
      final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
        gateway,
      );
      final subscription = source
          .watchCustomers(companyId: 'company-a')
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);

      await expectLater(subscription.cancel(), throwsStateError);
      expect(gateway.removed, hasLength(1));
    },
  );
  test('Drivers topic accepts only current-company Drivers hints', () async {
    final gateway = _FakeGateway();
    final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
      gateway,
    );
    final received = <RealtimeChangeSignal>[];
    final subscription = source
        .watchDrivers(companyId: 'company-a')
        .listen(received.add);
    await Future<void>.delayed(Duration.zero);

    final channel = gateway.channels.single;
    expect(channel.topic, RealtimeTopics.drivers('company-a'));
    channel.onStatus(RealtimeChannelJoinStatus.subscribed);
    channel.onMessage({
      'payload': {'company_id': 'company-a', 'resource': 'customers'},
    });
    channel.onMessage({
      'payload': {'company_id': 'company-b', 'resource': 'drivers'},
    });
    channel.onMessage({
      'payload': {'company_id': 'company-a', 'resource': 'drivers'},
    });
    await Future<void>.delayed(Duration.zero);

    expect(received, [
      RealtimeChangeSignal.subscribed,
      RealtimeChangeSignal.changed,
    ]);
    await subscription.cancel();
    expect(gateway.removed, [channel]);
  });
}

final class _FakeGateway implements RealtimeChannelGateway {
  @override
  String? accessToken = 'development-test-token';
  Completer<void>? authBarrier;
  bool failRemoval = false;
  final List<String> authTokens = [];
  final List<_FakeHandle> channels = [];
  final List<_FakeHandle> removed = [];

  @override
  Future<void> authenticate(String token) async {
    authTokens.add(token);
    final barrier = authBarrier;
    if (barrier != null) await barrier.future;
  }

  @override
  RealtimeChannelHandle subscribe({
    required String topic,
    required String event,
    required void Function(Map<String, dynamic>) onMessage,
    required void Function(RealtimeChannelJoinStatus) onStatus,
  }) {
    final handle = _FakeHandle(
      topic: topic,
      event: event,
      onMessage: onMessage,
      onStatus: onStatus,
    );
    channels.add(handle);
    return handle;
  }

  @override
  Future<void> remove(RealtimeChannelHandle handle) async {
    removed.add(handle as _FakeHandle);
    if (failRemoval) throw StateError('simulated cleanup failure');
  }
}

final class _FakeHandle implements RealtimeChannelHandle {
  final String topic;
  final String event;
  final void Function(Map<String, dynamic>) onMessage;
  final void Function(RealtimeChannelJoinStatus) onStatus;

  const _FakeHandle({
    required this.topic,
    required this.event,
    required this.onMessage,
    required this.onStatus,
  });
}
