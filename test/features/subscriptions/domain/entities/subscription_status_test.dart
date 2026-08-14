import 'package:horus_system/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:test/test.dart';

void main() {
  test('tryParse returns typed subscription statuses from database values', () {
    expect(
      SubscriptionStatusX.tryParse('trialing'),
      SubscriptionStatus.trialing,
    );
    expect(SubscriptionStatusX.tryParse('active'), SubscriptionStatus.active);
    expect(
      SubscriptionStatusX.tryParse('past_due'),
      SubscriptionStatus.pastDue,
    );
    expect(
      SubscriptionStatusX.tryParse('cancelled'),
      SubscriptionStatus.cancelled,
    );
    expect(SubscriptionStatusX.tryParse('expired'), SubscriptionStatus.expired);
    expect(
      SubscriptionStatusX.tryParse('suspended'),
      SubscriptionStatus.suspended,
    );
  });

  test('tryParse returns null for unsupported values', () {
    expect(SubscriptionStatusX.tryParse('unknown'), isNull);
  });
}
