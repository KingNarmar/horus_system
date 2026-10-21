import 'dart:convert';

/// Minimal Phoenix 1.0.0 messages for Development-only RLS verification.
enum RealtimeJoinVerdict { allowed, denied, inconclusive }

String financeTopic(String companyId, String resource) =>
    'realtime:horus:company:$companyId:$resource';

Map<String, Object?> joinFinanceTopic({
  required String topic,
  required String ref,
  String? jwt,
}) => {
  'topic': topic,
  'event': 'phx_join',
  'join_ref': ref,
  'ref': ref,
  'payload': {
    'config': {
      'private': true,
      'broadcast': {'self': false, 'ack': false},
      'presence': {'enabled': false},
      'postgres_changes': <Object>[],
    },
    if (jwt != null) 'access_token': jwt,
  },
};

RealtimeJoinVerdict? parseFinanceJoinResult(
  Object? message, {
  required String topic,
  required String ref,
}) {
  try {
    final json = message is String ? jsonDecode(message) : message;
    if (json is! Map ||
        json['topic'] != topic ||
        json['event'] != 'phx_reply' ||
        json['ref'] != ref) {
      return null;
    }
    final payload = json['payload'];
    if (payload is! Map) return RealtimeJoinVerdict.inconclusive;
    if (payload['status'] == 'ok') return RealtimeJoinVerdict.allowed;
    if (payload['status'] != 'error') {
      return RealtimeJoinVerdict.inconclusive;
    }

    final response = payload['response'];
    final reason = response is Map ? response['reason'] : null;
    if (reason is! String) return RealtimeJoinVerdict.inconclusive;
    final normalized = reason.toLowerCase();
    if ([
      'unauthorized',
      'forbidden',
      'permission',
      'not authorized',
      'access denied',
      'row-level security',
      'rls',
    ].any(normalized.contains)) {
      return RealtimeJoinVerdict.denied;
    }
    return RealtimeJoinVerdict.inconclusive;
  } catch (_) {
    return RealtimeJoinVerdict.inconclusive;
  }
}
