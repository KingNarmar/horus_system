// Pure decoding and verdicts for Development-only Issue #317 R4.4
// Realtime Broadcast forgery checks. No network, business data or SDK calls.
//
// Supabase Realtime may SILENTLY drop RLS-denied Broadcast pushes, even with
// config.broadcast.ack=true. Silence alone is NOT an explicit denial.
// https://supabase.com/docs/guides/realtime/protocol

import 'dart:convert';

enum R44BroadcastOutcome {
  explicitlyDenied,
  noDeliveryObserved,
  delivered,
  inconclusive,
}

enum R44SenderAck {
  explicitlyDenied,
  accepted,
  silent,
  unrelatedError,
}

Object? _frame(Object? raw) {
  if (raw is! String) return raw;
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}

R44SenderAck? r44SenderAckFromFrame(
  Object? raw, {
  required String topic,
  required String ref,
}) {
  final data = _frame(raw);
  if (data is! Map ||
      data['topic'] != topic ||
      data['event'] != 'phx_reply' ||
      data['ref'] != ref) {
    return null;
  }
  final payload = data['payload'];
  if (payload is! Map) return R44SenderAck.unrelatedError;
  if (payload['status'] == 'ok') return R44SenderAck.accepted;
  if (payload['status'] != 'error') return R44SenderAck.unrelatedError;
  final response = payload['response'];
  if (response is! Map) return R44SenderAck.unrelatedError;
  final text = (response['reason'] ?? response['error'])?.toString()
      .toLowerCase();
  if (text == null) return R44SenderAck.unrelatedError;
  return [
    'unauthorized',
    'not authorized',
    'forbidden',
    'permission',
    'access denied',
    'row-level security',
    'rls',
  ].any(text.contains)
      ? R44SenderAck.explicitlyDenied
      : R44SenderAck.unrelatedError;
}

bool r44IsObserverHeartbeat(
  Object? raw, {
  required String ref,
}) {
  final data = _frame(raw);
  if (data is! Map ||
      data['topic'] != 'phoenix' ||
      data['event'] != 'phx_reply' ||
      data['ref'] != ref) {
    return false;
  }
  final payload = data['payload'];
  return payload is Map && payload['status'] == 'ok';
}

bool r44IsForgedEvent(
  Object? raw, {
  required String topic,
  required String marker,
}) {
  final data = _frame(raw);
  if (data is! Map ||
      data['topic'] != topic ||
      data['event'] != 'broadcast') {
    return false;
  }
  final envelope = data['payload'];
  if (envelope is! Map ||
      envelope['type'] != 'broadcast' ||
      envelope['event'] != 'changed') {
    return false;
  }
  final payload = envelope['payload'];
  return payload is Map && payload['qa_probe'] == marker;
}

bool r44IsChannelTerminated(Object? raw, {required String topic}) {
  final data = _frame(raw);
  if (data is! Map || data['topic'] != topic) return false;
  if (data['event'] == 'phx_error' || data['event'] == 'phx_close') {
    return true;
  }
  if (data['event'] != 'system') return false;
  final payload = data['payload'];
  return payload is Map && payload['status'] == 'error';
}

R44BroadcastOutcome r44EvaluateBroadcast({
  required R44SenderAck sender,
  required bool forgedEventObserved,
  required bool observerHeartbeatOk,
  required bool fullObservationWindow,
  required bool observerDisconnected,
}) {
  // Accepted sender ACK or independently delivered event is a security FAIL.
  if (sender == R44SenderAck.accepted || forgedEventObserved) {
    return R44BroadcastOutcome.delivered;
  }
  if (sender == R44SenderAck.explicitlyDenied) {
    return R44BroadcastOutcome.explicitlyDenied;
  }
  if (observerHeartbeatOk &&
      fullObservationWindow &&
      !observerDisconnected &&
      sender == R44SenderAck.silent) {
    // This is supporting evidence, NOT a standalone proof of RLS denial.
    return R44BroadcastOutcome.noDeliveryObserved;
  }
  return R44BroadcastOutcome.inconclusive;
}
