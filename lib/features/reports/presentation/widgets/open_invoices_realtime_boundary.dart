import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/realtime/domain/entities/company_invalidation_resource.dart';
import '../../../../core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/policies/reports_permission_policy.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../helpers/reports_failure_message.dart';

/// R4.5: only the visible open-invoices projection reacts to invoice changes.
final class OpenInvoicesRealtimeBoundary extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final Widget child;

  const OpenInvoicesRealtimeBoundary({
    required this.currentCompanyContext,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!ReportsPermissionPolicy.canViewOpenInvoicesReport(
      currentCompanyContext.role,
    )) {
      return child;
    }
    return CompanyResourceInvalidationBoundary(
      companyId: currentCompanyContext.companyId,
      resources: const {CompanyInvalidationResource.openInvoicesReport},
      onInvalidate: (context) => context
          .read<ReportsCubit>()
          .refreshOpenInvoicesFromRealtime(),
      child: BlocListener<ReportsCubit, ReportsState>(
        listenWhen: (previous, current) =>
            current is ReportsLoaded &&
            current.realtimeRefreshFailure != null &&
            (previous is! ReportsLoaded ||
                previous.realtimeRefreshFailure?.code !=
                    current.realtimeRefreshFailure?.code),
        listener: (context, current) {
          if (current is! ReportsLoaded) return;
          final failure = current.realtimeRefreshFailure;
          if (failure == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(reportsFailureMessage(context, failure))),
          );
        },
        child: child,
      ),
    );
  }
}
