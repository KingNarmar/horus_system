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

  test('Driver Settlements private channel rejects foreign payloads', () async {
    final gateway = _FakeGateway();
    final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
      gateway,
    );
    final received = <RealtimeChangeSignal>[];
    final subscription = source
        .watchDriverSettlements(companyId: 'company-a')
        .listen(received.add);
    await Future<void>.delayed(Duration.zero);

    final channel = gateway.channels.single;
    expect(channel.topic, RealtimeTopics.driverSettlements('company-a'));
    expect(channel.event, RealtimeTopics.customersChangedEvent);
    channel.onStatus(RealtimeChannelJoinStatus.subscribed);
    channel.onMessage({
      'payload': {'company_id': 'company-b', 'resource': 'driver_settlements'},
    });
    channel.onMessage({
      'payload': {'company_id': 'company-a', 'resource': 'driver_finance'},
    });
    channel.onMessage({
      'payload': {'company_id': 'company-a', 'resource': 'driver_settlements'},
    });
    await Future<void>.delayed(Duration.zero);
    expect(received, [
      RealtimeChangeSignal.subscribed,
      RealtimeChangeSignal.changed,
    ]);

    await subscription.cancel();
    expect(gateway.removed, [channel]);
  });

  test(
    'Invoices topic rejects other tenants, resources and malformed hints',
    () async {
      final gateway = _FakeGateway();
      final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
        gateway,
      );
      final received = <RealtimeChangeSignal>[];
      final subscription = source
          .watchInvoices(companyId: 'company-a')
          .listen(received.add);
      await Future<void>.delayed(Duration.zero);

      final channel = gateway.channels.single;
      expect(channel.topic, RealtimeTopics.invoices('company-a'));
      expect(channel.event, RealtimeTopics.customersChangedEvent);
      channel.onStatus(RealtimeChannelJoinStatus.subscribed);
      channel.onMessage({
        'payload': {'company_id': 'company-b', 'resource': 'invoices'},
      });
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'payments'},
      });
      channel.onMessage({
        'payload': {'resource': 'invoices'},
      });
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'invoices'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(received, [
        RealtimeChangeSignal.subscribed,
        RealtimeChangeSignal.changed,
      ]);
      await subscription.cancel();
      expect(gateway.removed, [channel]);
    },
  );

  test('Payments topic accepts only authorized-shaped current-company hints', () async {
    final gateway = _FakeGateway();
    final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
      gateway,
    );
    final received = <RealtimeChangeSignal>[];
    final subscription = source
        .watchPayments(companyId: 'company-a')
        .listen(received.add);
    await Future<void>.delayed(Duration.zero);

    final channel = gateway.channels.single;
    expect(channel.topic, RealtimeTopics.payments('company-a'));
    expect(channel.event, RealtimeTopics.customersChangedEvent);
    channel.onStatus(RealtimeChannelJoinStatus.subscribed);
    channel.onMessage({
      'payload': {'company_id': 'company-b', 'resource': 'payments'},
    });
    channel.onMessage({
      'payload': {'company_id': 'company-a', 'resource': 'invoices'},
    });
    channel.onMessage({
      'payload': {'resource': 'payments'},
    });
    channel.onMessage({
      'payload': {'company_id': 'company-a', 'resource': 'payments'},
    });
    await Future<void>.delayed(Duration.zero);
    expect(received, [
      RealtimeChangeSignal.subscribed,
      RealtimeChangeSignal.changed,
    ]);

    await subscription.cancel();
    expect(gateway.removed, [channel]);
  });

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
  test('Trips topic only accepts current-company Trip hints', () async {
    final gateway = _FakeGateway();
    final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
      gateway,
    );
    final received = <RealtimeChangeSignal>[];
    final subscription = source
        .watchTrips(companyId: 'company-a')
        .listen(received.add);
    await Future<void>.delayed(Duration.zero);

    final channel = gateway.channels.single;
    expect(channel.topic, RealtimeTopics.trips('company-a'));
    channel.onStatus(RealtimeChannelJoinStatus.subscribed);
    channel.onMessage({
      'payload': {'company_id': 'company-b', 'resource': 'trips'},
    });
    channel.onMessage({
      'payload': {'company_id': 'company-a', 'resource': 'routes'},
    });
    channel.onMessage({
      'payload': {'company_id': 'company-a', 'resource': 'trips'},
    });
    await Future<void>.delayed(Duration.zero);
    expect(received, [
      RealtimeChangeSignal.subscribed,
      RealtimeChangeSignal.changed,
    ]);
    await subscription.cancel();
    expect(gateway.removed, [channel]);
  });

  test(
    'Routes private topic rejects cross-tenant and wrong-resource hints',
    () async {
      final gateway = _FakeGateway();
      final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
        gateway,
      );
      final received = <RealtimeChangeSignal>[];
      final subscription = source
          .watchRoutes(companyId: 'company-a')
          .listen(received.add);
      await Future<void>.delayed(Duration.zero);

      final channel = gateway.channels.single;
      expect(channel.topic, RealtimeTopics.routes('company-a'));
      expect(channel.event, RealtimeTopics.customersChangedEvent);
      channel.onStatus(RealtimeChannelJoinStatus.subscribed);
      channel.onMessage({
        'payload': {'company_id': 'company-b', 'resource': 'routes'},
      });
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'drivers'},
      });
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'routes'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(received, [
        RealtimeChangeSignal.subscribed,
        RealtimeChangeSignal.changed,
      ]);
      await subscription.cancel();
      expect(gateway.removed, [channel]);
    },
  );

  test(
    'Trip Documents private topic ignores foreign-company and wrong-resource hints',
    () async {
      final gateway = _FakeGateway();
      final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
        gateway,
      );
      final received = <RealtimeChangeSignal>[];
      final subscription = source
          .watchTripDocuments(companyId: 'company-a')
          .listen(received.add);
      await Future<void>.delayed(Duration.zero);

      final channel = gateway.channels.single;
      expect(channel.topic, RealtimeTopics.tripDocuments('company-a'));
      expect(channel.event, RealtimeTopics.customersChangedEvent);
      channel.onStatus(RealtimeChannelJoinStatus.subscribed);
      channel.onMessage({
        'payload': {'company_id': 'company-b', 'resource': 'trip_documents'},
      });
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'trips'},
      });
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'trip_documents'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(received, [
        RealtimeChangeSignal.subscribed,
        RealtimeChangeSignal.changed,
      ]);
      await subscription.cancel();
      expect(gateway.removed, [channel]);
    },
  );

  test(
    'Company Expenses private topic accepts only its own minimal hints',
    () async {
      final gateway = _FakeGateway();
      final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
        gateway,
      );
      final received = <RealtimeChangeSignal>[];
      final subscription = source
          .watchCompanyExpenses(companyId: 'company-a')
          .listen(received.add);
      await Future<void>.delayed(Duration.zero);

      final channel = gateway.channels.single;
      expect(channel.topic, RealtimeTopics.companyExpenses('company-a'));
      channel.onStatus(RealtimeChannelJoinStatus.subscribed);
      channel.onMessage({
        'payload': {'company_id': 'company-b', 'resource': 'company_expenses'},
      });
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'expense_ledger'},
      });
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'company_expenses'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(received, [
        RealtimeChangeSignal.subscribed,
        RealtimeChangeSignal.changed,
      ]);
      await subscription.cancel();
      expect(gateway.removed, [channel]);
    },
  );

  test('financial topics use distinct private scoped payloads', () async {
    final gateway = _FakeGateway();
    final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
      gateway,
    );
    final ledgerSignals = <RealtimeChangeSignal>[];
    final tripSignals = <RealtimeChangeSignal>[];
    final ledgerSubscription = source
        .watchExpenseLedger(companyId: 'company-a')
        .listen(ledgerSignals.add);
    final tripSubscription = source
        .watchTripExpenses(companyId: 'company-a')
        .listen(tripSignals.add);
    await Future<void>.delayed(Duration.zero);

    expect(gateway.channels, hasLength(2));
    final ledger = gateway.channels[0];
    final tripExpenses = gateway.channels[1];
    expect(ledger.topic, RealtimeTopics.expenseLedger('company-a'));
    expect(tripExpenses.topic, RealtimeTopics.tripExpenses('company-a'));

    ledger.onMessage({
      'payload': {'company_id': 'company-b', 'resource': 'expense_ledger'},
    });
    ledger.onMessage({
      'payload': {'company_id': 'company-a', 'resource': 'trip_expenses'},
    });
    ledger.onMessage({
      'payload': {'company_id': 'company-a', 'resource': 'expense_ledger'},
    });
    tripExpenses.onMessage({
      'payload': {'company_id': 'company-b', 'resource': 'trip_expenses'},
    });
    tripExpenses.onMessage({
      'payload': {'company_id': 'company-a', 'resource': 'expense_ledger'},
    });
    tripExpenses.onMessage({
      'payload': {'company_id': 'company-a', 'resource': 'trip_expenses'},
    });
    await Future<void>.delayed(Duration.zero);

    expect(ledgerSignals, [RealtimeChangeSignal.changed]);
    expect(tripSignals, [RealtimeChangeSignal.changed]);
    await ledgerSubscription.cancel();
    await tripSubscription.cancel();
    expect(gateway.removed, [ledger, tripExpenses]);
  });

  test(
    'Driver Finance topic ignores cross-tenant and wrong-resource hints',
    () async {
      final gateway = _FakeGateway();
      final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
        gateway,
      );
      final received = <RealtimeChangeSignal>[];
      final subscription = source
          .watchDriverFinance(companyId: 'company-a')
          .listen(received.add);
      await Future<void>.delayed(Duration.zero);
      final channel = gateway.channels.single;
      expect(channel.topic, RealtimeTopics.driverFinance('company-a'));
      channel.onStatus(RealtimeChannelJoinStatus.subscribed);
      channel.onMessage({
        'payload': {'company_id': 'company-b', 'resource': 'driver_finance'},
      });
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'expense_ledger'},
      });
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'driver_finance'},
      });
      await Future<void>.delayed(Duration.zero);
      expect(received, [
        RealtimeChangeSignal.subscribed,
        RealtimeChangeSignal.changed,
      ]);
      await subscription.cancel();
      expect(gateway.removed, [channel]);
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
  test(
    'Fleet license documents subscribe privately and reject foreign hints',
    () async {
      final gateway = _FakeGateway();
      final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
        gateway,
      );
      final events = <RealtimeChangeSignal>[];
      final subscription = source
          .watchFleetLicenseDocuments(companyId: 'company-a')
          .listen(events.add);
      await Future<void>.delayed(Duration.zero);

      final channel = gateway.channels.single;
      expect(channel.topic, RealtimeTopics.fleetLicenseDocuments('company-a'));
      channel.onStatus(RealtimeChannelJoinStatus.subscribed);
      channel.onMessage({
        'payload': {
          'company_id': 'company-b',
          'resource': 'fleet_license_documents',
        },
      });
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'fleet'},
      });
      channel.onMessage({
        'payload': {
          'company_id': 'company-a',
          'resource': 'fleet_license_documents',
        },
      });
      await Future<void>.delayed(Duration.zero);

      expect(events, [
        RealtimeChangeSignal.subscribed,
        RealtimeChangeSignal.changed,
      ]);
      await subscription.cancel();
      expect(gateway.removed, [channel]);
    },
  );

  test(
    'Fleet private topic accepts only current-company Fleet hints',
    () async {
      final gateway = _FakeGateway();
      final source = SupabaseCompanyDataChangesRemoteDataSource.withGateway(
        gateway,
      );
      final events = <RealtimeChangeSignal>[];
      final subscription = source
          .watchFleet(companyId: 'company-a')
          .listen(events.add);
      await Future<void>.delayed(Duration.zero);

      final channel = gateway.channels.single;
      expect(channel.topic, RealtimeTopics.fleet('company-a'));
      expect(channel.event, RealtimeTopics.customersChangedEvent);

      channel.onStatus(RealtimeChannelJoinStatus.subscribed);
      channel.onMessage({
        'payload': {'company_id': 'company-b', 'resource': 'fleet'},
      });
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'drivers'},
      });
      channel.onMessage({
        'payload': {'company_id': 'company-a', 'resource': 'fleet'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(events, [
        RealtimeChangeSignal.subscribed,
        RealtimeChangeSignal.changed,
      ]);
      await subscription.cancel();
      expect(gateway.removed, [channel]);
    },
  );
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
