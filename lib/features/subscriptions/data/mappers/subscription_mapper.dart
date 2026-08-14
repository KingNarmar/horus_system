import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/company_subscription.dart';
import '../../domain/entities/plan_limit.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_status.dart';
import '../models/company_subscription_model.dart';
import '../models/subscription_plan_model.dart';

extension SubscriptionPlanModelMapper on SubscriptionPlanModel {
  SubscriptionPlan toEntity() {
    return SubscriptionPlan(
      id: id,
      code: code,
      name: name,
      monthlyPrice: monthlyPrice,
      maxUsers: PlanLimit(maxUsers),
      maxVehicles: PlanLimit(maxVehicles),
      maxTripsPerMonth: PlanLimit(maxTripsPerMonth),
      hasDriverApp: hasDriverApp,
      hasAdvancedReports: hasAdvancedReports,
      hasDocumentUpload: hasDocumentUpload,
      hasMaintenance: hasMaintenance,
      hasWhatsappNotifications: hasWhatsappNotifications,
      isActive: isActive,
    );
  }
}

extension CompanySubscriptionModelMapper on CompanySubscriptionModel {
  Result<CompanySubscription> toEntityResult() {
    final parsedStatus = SubscriptionStatusX.tryParse(status);
    if (parsedStatus == null) {
      return const FailureResult<CompanySubscription>(
        ServerFailure(
          code: FailureCodes.subscriptionStatusInvalid,
          message: 'Subscription status is not supported.',
        ),
      );
    }

    return Success(
      CompanySubscription(
        id: id,
        companyId: companyId,
        planId: planId,
        status: parsedStatus,
        trialEndsAt: trialEndsAt,
        currentPeriodStart: currentPeriodStart,
        currentPeriodEnd: currentPeriodEnd,
        externalProvider: externalProvider,
        plan: plan.toEntity(),
      ),
    );
  }
}
