import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/company_entitlement.dart';
import '../../domain/entities/company_quota_snapshot.dart';

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
  final CompanyQuotaSnapshot quota;

  const SubscriptionsLoaded({
    required this.currentCompanyContext,
    required this.quota,
  });

  CompanyEntitlement get entitlement => quota.entitlement;
}

final class SubscriptionsFailure extends SubscriptionsState {
  final Failure failure;

  const SubscriptionsFailure(this.failure);
}
