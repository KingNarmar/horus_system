import '../constants/company_membership_realtime_topics.dart';

/// A Broadcast payload is untrusted and only triggers an authoritative re-read.
abstract final class CompanyMembershipChangeDecoder {
  static bool isForUser(
    Map<String, dynamic> envelope, {
    required String userId,
  }) {
    final payload = envelope['payload'];
    return payload is Map &&
        payload['user_id'] == userId &&
        payload['resource'] ==
            CompanyMembershipRealtimeTopics.membershipResource;
  }
}
