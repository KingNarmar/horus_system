import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/company_subscription.dart';
import '../../domain/entities/subscription_plan.dart';

sealed class SubscriptionsState {
  const SubscriptionsState();
}

final class SubscriptionsInitial extends SubscriptionsState {
  const SubscriptionsInitial();
}

final class SubscriptionsLoading extends SubscriptionsState {
  const SubscriptionsLoading();
}

final class SubscriptionsLoaded extends SubscriptionsState {
  final CurrentCompanyContext currentCompanyContext;
  final List<SubscriptionPlan> plans;
  final CompanySubscription? currentSubscription;

  const SubscriptionsLoaded({
    required this.currentCompanyContext,
    required this.plans,
    required this.currentSubscription,
  });

  bool get hasCurrentSubscription => currentSubscription != null;
}

final class SubscriptionsFailure extends SubscriptionsState {
  final Failure failure;

  const SubscriptionsFailure(this.failure);
}
