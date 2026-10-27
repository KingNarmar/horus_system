abstract final class CompanyMembershipRealtimeTopics {
  static const changedEvent = 'changed';
  static const membershipResource = 'membership';

  static String userMemberships(String userId) =>
      'horus:user:$userId:membership';
}
