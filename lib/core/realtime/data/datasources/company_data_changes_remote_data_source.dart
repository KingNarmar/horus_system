import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/realtime_topics.dart';
import '../models/realtime_change_signal.dart';

abstract interface class CompanyDataChangesRemoteDataSource {
  Stream<RealtimeChangeSignal> watchCustomers({required String companyId});
}

final class SupabaseCompanyDataChangesRemoteDataSource
    implements CompanyDataChangesRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCompanyDataChangesRemoteDataSource(this._client);

  @override
  Stream<RealtimeChangeSignal> watchCustomers({required String companyId}) {
    late final StreamController<RealtimeChangeSignal> controller;
    RealtimeChannel? channel;
    var disposed = false;

    void addSignal(RealtimeChangeSignal signal) {
      if (!disposed && !controller.isClosed) {
        controller.add(signal);
      }
    }

    Future<void> connect() async {
      try {
        final token = _client.auth.currentSession?.accessToken;
        if (token == null) {
          addSignal(RealtimeChangeSignal.unavailable);
          return;
        }

        await _client.realtime.setAuth(token);
        if (disposed) return;

        final activeChannel = _client.channel(
          RealtimeTopics.customers(companyId),
          opts: const RealtimeChannelConfig(private: true),
        );
        channel = activeChannel;

        activeChannel
            .onBroadcast(
              event: RealtimeTopics.customersChangedEvent,
              callback: (payload) {
                final body = payload['payload'];
                if (body is! Map ||
                    body['company_id'] != companyId ||
                    body['resource'] != RealtimeTopics.customersResource) {
                  return;
                }
                addSignal(RealtimeChangeSignal.changed);
              },
            )
            .subscribe((status, _) {
              if (status == RealtimeSubscribeStatus.subscribed) {
                // A join (including resubscription) must reconcile missed work.
                addSignal(RealtimeChangeSignal.subscribed);
              } else if (status == RealtimeSubscribeStatus.channelError ||
                  status == RealtimeSubscribeStatus.timedOut) {
                addSignal(RealtimeChangeSignal.unavailable);
              }
            });
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
          await _client.removeChannel(activeChannel);
        }
      },
    );

    return controller.stream;
  }
}
