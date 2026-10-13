import '../constants/realtime_topics.dart';

/// Validates an untrusted Broadcast envelope before it can become an
/// authoritative reload hint. Never decodes customer records from messages.
abstract final class CustomersChangeMessageDecoder {
  static bool isForCompany(
    Map<String, dynamic> envelope, {
    required String companyId,
  }) {
    final payload = envelope['payload'];
    if (payload is! Map) return false;

    return payload['company_id'] == companyId &&
        payload['resource'] == RealtimeTopics.customersResource;
  }
}
