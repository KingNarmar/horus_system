import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../constants/realtime_topics.dart';
import '../mappers/company_change_message_decoder.dart';
import '../models/realtime_change_signal.dart';
import 'realtime_channel_gateway.dart';

abstract interface class CompanyDataChangesRemoteDataSource {
  Stream<RealtimeChangeSignal> watchCustomers({required String companyId});

  Stream<RealtimeChangeSignal> watchDrivers({required String companyId});

  Stream<RealtimeChangeSignal> watchFleet({required String companyId});

  Stream<RealtimeChangeSignal> watchRoutes({required String companyId});

  Stream<RealtimeChangeSignal> watchTrips({required String companyId});

  Stream<RealtimeChangeSignal> watchTripDocuments({required String companyId});

  Stream<RealtimeChangeSignal> watchCompanyExpenses({
    required String companyId,
  });

  Stream<RealtimeChangeSignal> watchDriverFinance({required String companyId});

  Stream<RealtimeChangeSignal> watchDriverSettlements({
    required String companyId,
  });

  Stream<RealtimeChangeSignal> watchInvoices({required String companyId});

  Stream<RealtimeChangeSignal> watchExpenseLedger({required String companyId});

  Stream<RealtimeChangeSignal> watchTripExpenses({required String companyId});

  Stream<RealtimeChangeSignal> watchFleetLicenseDocuments({
    required String companyId,
  });
}

final class SupabaseCompanyDataChangesRemoteDataSource
    implements CompanyDataChangesRemoteDataSource {
  final RealtimeChannelGateway _gateway;

  SupabaseCompanyDataChangesRemoteDataSource(SupabaseClient client)
    : _gateway = SupabaseRealtimeChannelGateway(client);

  /// Injectable transport allows deterministic teardown and reconnect tests.
  const SupabaseCompanyDataChangesRemoteDataSource.withGateway(this._gateway);

  @override
  Stream<RealtimeChangeSignal> watchCustomers({required String companyId}) =>
      _watchResource(
        companyId: companyId,
        topic: RealtimeTopics.customers(companyId),
        resource: RealtimeTopics.customersResource,
      );

  @override
  Stream<RealtimeChangeSignal> watchDrivers({required String companyId}) =>
      _watchResource(
        companyId: companyId,
        topic: RealtimeTopics.drivers(companyId),
        resource: RealtimeTopics.driversResource,
      );

  @override
  Stream<RealtimeChangeSignal> watchFleet({required String companyId}) =>
      _watchResource(
        companyId: companyId,
        topic: RealtimeTopics.fleet(companyId),
        resource: RealtimeTopics.fleetResource,
      );

  @override
  Stream<RealtimeChangeSignal> watchRoutes({required String companyId}) =>
      _watchResource(
        companyId: companyId,
        topic: RealtimeTopics.routes(companyId),
        resource: RealtimeTopics.routesResource,
      );

  @override
  Stream<RealtimeChangeSignal> watchTrips({required String companyId}) =>
      _watchResource(
        companyId: companyId,
        topic: RealtimeTopics.trips(companyId),
        resource: RealtimeTopics.tripsResource,
      );

  @override
  Stream<RealtimeChangeSignal> watchCompanyExpenses({
    required String companyId,
  }) => _watchResource(
    companyId: companyId,
    topic: RealtimeTopics.companyExpenses(companyId),
    resource: RealtimeTopics.companyExpensesResource,
  );

  @override
  Stream<RealtimeChangeSignal> watchDriverFinance({
    required String companyId,
  }) => _watchResource(
    companyId: companyId,
    topic: RealtimeTopics.driverFinance(companyId),
    resource: RealtimeTopics.driverFinanceResource,
  );

  @override
  Stream<RealtimeChangeSignal> watchDriverSettlements({
    required String companyId,
  }) => _watchResource(
    companyId: companyId,
    topic: RealtimeTopics.driverSettlements(companyId),
    resource: RealtimeTopics.driverSettlementsResource,
  );

  @override
  Stream<RealtimeChangeSignal> watchInvoices({required String companyId}) =>
      _watchResource(
        companyId: companyId,
        topic: RealtimeTopics.invoices(companyId),
        resource: RealtimeTopics.invoicesResource,
      );

  @override
  Stream<RealtimeChangeSignal> watchExpenseLedger({
    required String companyId,
  }) => _watchResource(
    companyId: companyId,
    topic: RealtimeTopics.expenseLedger(companyId),
    resource: RealtimeTopics.expenseLedgerResource,
  );

  @override
  Stream<RealtimeChangeSignal> watchTripExpenses({required String companyId}) =>
      _watchResource(
        companyId: companyId,
        topic: RealtimeTopics.tripExpenses(companyId),
        resource: RealtimeTopics.tripExpensesResource,
      );

  @override
  Stream<RealtimeChangeSignal> watchTripDocuments({
    required String companyId,
  }) => _watchResource(
    companyId: companyId,
    topic: RealtimeTopics.tripDocuments(companyId),
    resource: RealtimeTopics.tripDocumentsResource,
  );

  @override
  Stream<RealtimeChangeSignal> watchFleetLicenseDocuments({
    required String companyId,
  }) => _watchResource(
    companyId: companyId,
    topic: RealtimeTopics.fleetLicenseDocuments(companyId),
    resource: RealtimeTopics.fleetLicenseDocumentsResource,
  );

  Stream<RealtimeChangeSignal> _watchResource({
    required String companyId,
    required String topic,
    required String resource,
  }) {
    late final StreamController<RealtimeChangeSignal> controller;
    RealtimeChannelHandle? channel;
    var disposed = false;

    void addSignal(RealtimeChangeSignal signal) {
      if (!disposed && !controller.isClosed) {
        controller.add(signal);
      }
    }

    Future<void> connect() async {
      try {
        final token = _gateway.accessToken;
        if (token == null) {
          addSignal(RealtimeChangeSignal.unavailable);
          return;
        }

        await _gateway.authenticate(token);
        if (disposed) return;

        channel = _gateway.subscribe(
          topic: topic,
          event: RealtimeTopics.customersChangedEvent,
          onMessage: (payload) {
            if (CompanyChangeMessageDecoder.isForCompanyAndResource(
              payload,
              companyId: companyId,
              resource: resource,
            )) {
              addSignal(RealtimeChangeSignal.changed);
            }
          },
          onStatus: (status) {
            if (status == RealtimeChannelJoinStatus.subscribed) {
              // Includes SDK rejoin: fetch authoritative state after missed work.
              addSignal(RealtimeChangeSignal.subscribed);
            } else if (status == RealtimeChannelJoinStatus.unavailable) {
              addSignal(RealtimeChangeSignal.unavailable);
            }
          },
        );
      } catch (_) {
        addSignal(RealtimeChangeSignal.unavailable);
      }
    }

    controller = StreamController<RealtimeChangeSignal>(
      onListen: () => unawaited(connect()),
      onCancel: () async {
        disposed = true;
        final activeChannel = channel;
        if (activeChannel != null) {
          await _gateway.remove(activeChannel);
        }
      },
    );

    return controller.stream;
  }
}
