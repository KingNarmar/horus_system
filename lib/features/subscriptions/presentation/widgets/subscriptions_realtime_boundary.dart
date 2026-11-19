import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/realtime/domain/entities/company_invalidation_resource.dart';
import '../../../../core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/policies/entitlement_visibility_policy.dart';
import '../cubit/subscriptions_cubit.dart';

/// Observes existing company-session broadcasts without owning another channel.
final class SubscriptionsRealtimeBoundary extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final Widget child;

  const SubscriptionsRealtimeBoundary({
    required this.currentCompanyContext,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!EntitlementVisibilityPolicy.canView(currentCompanyContext.role)) {
      return child;
    }

    return CompanyResourceInvalidationBoundary(
      companyId: currentCompanyContext.companyId,
      resources: const {CompanyInvalidationResource.quotaUsage},
      onInvalidate: (context) => context.read<SubscriptionsCubit>().refresh(
        currentCompanyContext,
      ),
      child: child,
    );
  }
}
