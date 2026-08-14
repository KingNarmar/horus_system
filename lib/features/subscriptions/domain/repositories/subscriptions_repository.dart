import '../../../../core/utils/result.dart';
import '../entities/company_subscription.dart';
import '../entities/subscription_plan.dart';

abstract interface class SubscriptionsRepository {
  Future<Result<List<SubscriptionPlan>>> getAvailablePlans();

  Future<Result<CompanySubscription?>> getCurrentCompanySubscription({
    required String companyId,
  });
}
