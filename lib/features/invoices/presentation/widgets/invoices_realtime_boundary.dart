import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/realtime/domain/entities/company_invalidation_resource.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_cubit.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_state.dart';
import '../../../../core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/policies/invoices_permission_policy.dart';
import '../cubit/invoices_cubit.dart';
import '../cubit/invoices_state.dart';
import '../localization/invoice_failure_localizations_x.dart';

/// Invoice projections refresh only while the finance workspace is visible.
/// The company session owns the channel; this widget never creates one.
final class InvoicesRealtimeBoundary extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final Widget child;

  const InvoicesRealtimeBoundary({
    required this.currentCompanyContext,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!InvoicesPermissionPolicy.canViewInvoices(currentCompanyContext.role)) {
      return child;
    }
    return CompanyResourceInvalidationBoundary(
      companyId: currentCompanyContext.companyId,
      resources: const {CompanyInvalidationResource.invoices},
      onInvalidate: (context) =>
          context.read<InvoicesCubit>().refreshInvoicesFromRealtime(),
      child: CompanyResourceInvalidationBoundary(
        companyId: currentCompanyContext.companyId,
        resources: const {CompanyInvalidationResource.billableTrips},
        onInvalidate: (context) =>
            context.read<InvoicesCubit>().refreshBillableTripsFromRealtime(),
        child: MultiBlocListener(
          listeners: [
            BlocListener<CompanyRealtimeCubit, CompanyRealtimeState>(
              listenWhen: (previous, current) =>
                  current.companyId == currentCompanyContext.companyId &&
                  current.failure != null &&
                  previous.failure?.code != current.failure?.code,
              listener: (context, current) {
                final failure = current.failure;
                if (failure == null) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.localizedErrorMessage(failure)),
                  ),
                );
              },
            ),
            BlocListener<InvoicesCubit, InvoicesState>(
              listenWhen: (previous, current) =>
                  current is InvoicesLoaded &&
                  current.realtimeRefreshFailure != null &&
                  (previous is! InvoicesLoaded ||
                      previous.realtimeRefreshFailure?.code !=
                          current.realtimeRefreshFailure?.code),
              listener: (context, current) {
                if (current is! InvoicesLoaded) return;
                final failure = current.realtimeRefreshFailure;
                if (failure == null) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.localizedInvoiceFailure(failure))),
                );
              },
            ),
          ],
          child: child,
        ),
      ),
    );
  }
}
