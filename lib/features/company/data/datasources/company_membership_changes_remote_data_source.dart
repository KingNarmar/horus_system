import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../core/realtime/data/datasources/realtime_channel_gateway.dart';
import '../../../../core/realtime/data/models/realtime_change_signal.dart';
import '../constants/company_membership_realtime_topics.dart';
import '../mappers/company_membership_change_decoder.dart';

abstract interface class CompanyMembershipChangesRemoteDataSource {
  Stream<RealtimeChangeSignal> watchChanges({required String userId});
}

/// One private topic per authenticated user, independent of company membership.
/// A revoked member can still receive a hint to discard the old company shell.
final class SupabaseCompanyMembershipChangesRemoteDataSource
    implements CompanyMembershipChangesRemoteDataSource {
  final RealtimeChannelGateway _gateway;
  final String? Function() _currentUserId;

  SupabaseCompanyMembershipChangesRemoteDataSource(SupabaseClient client)
    : _gateway = SupabaseRealtimeChannelGateway(client),
      _currentUserId = (() => client.auth.currentUser?.id);

  const SupabaseCompanyMembershipChangesRemoteDataSource.withGateway(
    this._gateway,
    this._currentUserId,
  );

  @override
  Stream<RealtimeChangeSignal> watchChanges({required String userId}) {
    late final StreamController<RealtimeChangeSignal> controller;
    RealtimeChannelHandle? channel;
    var disposed = false;

    void notify(RealtimeChangeSignal signal) {
      if (!disposed && !controller.isClosed) controller.add(signal);
    }

    Future<void> connect() async {
      try {
        final token = _gateway.accessToken;
        if (token == null || _currentUserId() != userId) {
          notify(RealtimeChangeSignal.unavailable);
          return;
        }
        await _gateway.authenticate(token);
        if (disposed) return;

        channel = _gateway.subscribe(
          topic: CompanyMembershipRealtimeTopics.userMemberships(userId),
          event: CompanyMembershipRealtimeTopics.changedEvent,
          onMessage: (payload) {
            if (CompanyMembershipChangeDecoder.isForUser(
              payload,
              userId: userId,
            )) {
              notify(RealtimeChangeSignal.changed);
            }
          },
          onStatus: (status) {
            if (status == RealtimeChannelJoinStatus.subscribed) {
              // Initial join and reconnect reconcile missed mutations.
              notify(RealtimeChangeSignal.subscribed);
            } else if (status == RealtimeChannelJoinStatus.unavailable) {
              notify(RealtimeChangeSignal.unavailable);
            }
          },
        );
      } catch (_) {
        notify(RealtimeChangeSignal.unavailable);
      }
    }

    controller = StreamController<RealtimeChangeSignal>(
      onListen: () => unawaited(connect()),
      onCancel: () async {
        disposed = true;
        final activeChannel = channel;
        if (activeChannel != null) await _gateway.remove(activeChannel);
      },
    );
    return controller.stream;
  }
}
