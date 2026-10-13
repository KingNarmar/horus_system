import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../constants/realtime_topics.dart';
import '../mappers/customers_change_message_decoder.dart';
import '../models/realtime_change_signal.dart';
import 'realtime_channel_gateway.dart';

abstract interface class CompanyDataChangesRemoteDataSource {
  Stream<RealtimeChangeSignal> watchCustomers({required String companyId});
}

final class SupabaseCompanyDataChangesRemoteDataSource
    implements CompanyDataChangesRemoteDataSource {
  final RealtimeChannelGateway _gateway;

  SupabaseCompanyDataChangesRemoteDataSource(SupabaseClient client)
    : _gateway = SupabaseRealtimeChannelGateway(client);

  /// Injectable transport allows deterministic teardown and reconnect tests.
  const SupabaseCompanyDataChangesRemoteDataSource.withGateway(this._gateway);

  @override
  Stream<RealtimeChangeSignal> watchCustomers({required String companyId}) {
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
          topic: RealtimeTopics.customers(companyId),
          event: RealtimeTopics.customersChangedEvent,
          onMessage: (payload) {
            if (CustomersChangeMessageDecoder.isForCompany(
              payload,
              companyId: companyId,
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
