import 'dart:collection';
import 'dart:convert';

import 'uuid_v4.dart';

/// Keeps an ambiguous creation retry on the same server request identity.
///
/// A confirmed creation clears the key so a later intentional creation of
/// identical content consumes its own lifetime slot. Payload is serialized
/// using sorted keys; it contains only the current Data-layer RPC arguments.
final class CreationRetryRegistry {
  final Map<String, String> _pendingByPayload = <String, String>{};

  String keyFor(Map<String, dynamic> payload) {
    final signature = _signature(payload);
    return _pendingByPayload.putIfAbsent(signature, newUuidV4);
  }

  void markSucceeded(Map<String, dynamic> payload) {
    _pendingByPayload.remove(_signature(payload));
  }

  String _signature(Map<String, dynamic> payload) {
    return jsonEncode(SplayTreeMap<String, dynamic>.from(payload));
  }
}
