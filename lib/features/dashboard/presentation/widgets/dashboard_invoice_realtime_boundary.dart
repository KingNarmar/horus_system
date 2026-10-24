import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/realtime/domain/entities/company_invalidation_resource.dart';
import '../../../../core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/policies/dashboard_permission_policy.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

/// R4.5 invoice-derived dashboard refresh, finance roles only.
final class DashboardInvoiceRealtimeBoundary extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final Widget child;

  const DashboardInvoiceRealtimeBoundary({
    required this.currentCompanyContext,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!DashboardPermissionPolicy.canViewFinancialMetrics(
      currentCompanyContext.role,
    )) {
      return child;
    }
    return CompanyResourceInvalidationBoundary(
      companyId: currentCompanyContext.companyId,
      resources: const {CompanyInvalidationResource.dashboard},
      onInvalidate: (context) => context
          .read<DashboardCubit>()
          .refreshFinancialSummaryFromRealtime(),
      child: BlocListener<DashboardCubit, DashboardState>(
        listenWhen: (previous, current) =>
            current is DashboardLoaded &&
            current.realtimeRefreshFailure != null &&
            (previous is! DashboardLoaded ||
                previous.realtimeRefreshFailure?.code !=
                    current.realtimeRefreshFailure?.code),
        listener: (context, current) {
          if (current is! DashboardLoaded) return;
          final failure = current.realtimeRefreshFailure;
          if (failure == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.localizedErrorMessage(failure))),
          );
        },
        child: child,
      ),
    );
  }
}
