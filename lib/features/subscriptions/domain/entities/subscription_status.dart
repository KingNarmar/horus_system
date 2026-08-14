enum SubscriptionStatus {
  trialing,
  active,
  pastDue,
  cancelled,
  expired,
  suspended,
}

extension SubscriptionStatusX on SubscriptionStatus {
  String get value {
    return switch (this) {
      SubscriptionStatus.trialing => 'trialing',
      SubscriptionStatus.active => 'active',
      SubscriptionStatus.pastDue => 'past_due',
      SubscriptionStatus.cancelled => 'cancelled',
      SubscriptionStatus.expired => 'expired',
      SubscriptionStatus.suspended => 'suspended',
    };
  }

  static SubscriptionStatus? tryParse(String value) {
    return switch (value) {
      'trialing' => SubscriptionStatus.trialing,
      'active' => SubscriptionStatus.active,
      'past_due' => SubscriptionStatus.pastDue,
      'cancelled' => SubscriptionStatus.cancelled,
      'expired' => SubscriptionStatus.expired,
      'suspended' => SubscriptionStatus.suspended,
      _ => null,
    };
  }
}
