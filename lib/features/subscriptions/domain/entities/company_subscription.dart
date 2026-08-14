import 'subscription_plan.dart';
import 'subscription_status.dart';

final class CompanySubscription {
  final String id;
  final String companyId;
  final String planId;
  final SubscriptionStatus status;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final String? externalProvider;
  final SubscriptionPlan plan;

  const CompanySubscription({
    required this.id,
    required this.companyId,
    required this.planId,
    required this.status,
    required this.plan,
    this.trialEndsAt,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.externalProvider,
  });
}
