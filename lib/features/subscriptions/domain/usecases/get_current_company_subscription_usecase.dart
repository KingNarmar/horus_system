import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/company_subscription.dart';
import '../policies/subscriptions_permission_policy.dart';
import '../repositories/subscriptions_repository.dart';

final class GetCurrentCompanySubscriptionParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetCurrentCompanySubscriptionParams({
    required this.currentCompanyContext,
  });
}

final class GetCurrentCompanySubscriptionUseCase
    implements
        UseCase<CompanySubscription?, GetCurrentCompanySubscriptionParams> {
  final SubscriptionsRepository _repository;

  const GetCurrentCompanySubscriptionUseCase(this._repository);

  @override
  Future<Result<CompanySubscription?>> call(
    GetCurrentCompanySubscriptionParams params,
  ) {
    final context = params.currentCompanyContext;
    if (!SubscriptionsPermissionPolicy.canViewSubscriptions(context.role)) {
      return Future.value(
        const FailureResult<CompanySubscription?>(
          PermissionFailure(
            code: FailureCodes.permissionSubscriptionsView,
            message: 'Subscription view is not allowed.',
          ),
        ),
      );
    }

    final companyId = context.companyId.trim();
    if (companyId.isEmpty) {
      return Future.value(
        const FailureResult<CompanySubscription?>(
          ValidationFailure(
            code: FailureCodes.validationCompanyIdRequired,
            message: 'Company id is required.',
          ),
        ),
      );
    }

    return _repository.getCurrentCompanySubscription(companyId: companyId);
  }
}
