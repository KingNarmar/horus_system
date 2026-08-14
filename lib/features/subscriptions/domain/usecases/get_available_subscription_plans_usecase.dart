import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/subscription_plan.dart';
import '../policies/subscriptions_permission_policy.dart';
import '../repositories/subscriptions_repository.dart';

final class GetAvailableSubscriptionPlansParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetAvailableSubscriptionPlansParams({
    required this.currentCompanyContext,
  });
}

final class GetAvailableSubscriptionPlansUseCase
    implements
        UseCase<List<SubscriptionPlan>, GetAvailableSubscriptionPlansParams> {
  final SubscriptionsRepository _repository;

  const GetAvailableSubscriptionPlansUseCase(this._repository);

  @override
  Future<Result<List<SubscriptionPlan>>> call(
    GetAvailableSubscriptionPlansParams params,
  ) {
    if (!SubscriptionsPermissionPolicy.canViewSubscriptions(
      params.currentCompanyContext.role,
    )) {
      return Future.value(
        const FailureResult<List<SubscriptionPlan>>(
          PermissionFailure(
            code: FailureCodes.permissionSubscriptionsView,
            message: 'Subscription view is not allowed.',
          ),
        ),
      );
    }

    return _repository.getAvailablePlans();
  }
}
