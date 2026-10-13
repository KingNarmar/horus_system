import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase transport seam. Kept in Data so subscription cleanup can be
/// verified without real sockets or leaking SDK types into Domain or Cubits.
enum RealtimeChannelJoinStatus { subscribed, unavailable }

abstract interface class RealtimeChannelHandle {}

abstract interface class RealtimeChannelGateway {
  String? get accessToken;

  Future<void> authenticate(String token);

  RealtimeChannelHandle subscribe({
    required String topic,
    required String event,
    required void Function(Map<String, dynamic>) onMessage,
    required void Function(RealtimeChannelJoinStatus) onStatus,
  });

  Future<void> remove(RealtimeChannelHandle handle);
}

final class SupabaseRealtimeChannelGateway implements RealtimeChannelGateway {
  final SupabaseClient _client;

  const SupabaseRealtimeChannelGateway(this._client);

  @override
  String? get accessToken => _client.auth.currentSession?.accessToken;

  @override
  Future<void> authenticate(String token) async {
    await _client.realtime.setAuth(token);
  }

  @override
  RealtimeChannelHandle subscribe({
    required String topic,
    required String event,
    required void Function(Map<String, dynamic>) onMessage,
    required void Function(RealtimeChannelJoinStatus) onStatus,
  }) {
    final channel = _client.channel(
      topic,
      opts: const RealtimeChannelConfig(private: true),
    );

    channel.onBroadcast(event: event, callback: onMessage).subscribe((
      status,
      _,
    ) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        onStatus(RealtimeChannelJoinStatus.subscribed);
      } else if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        onStatus(RealtimeChannelJoinStatus.unavailable);
      }
    });

    return _SupabaseChannelHandle(channel);
  }

  @override
  Future<void> remove(RealtimeChannelHandle handle) async {
    final channel = (handle as _SupabaseChannelHandle).channel;
    await _client.removeChannel(channel);
  }
}

final class _SupabaseChannelHandle implements RealtimeChannelHandle {
  final RealtimeChannel channel;

  const _SupabaseChannelHandle(this.channel);
}
