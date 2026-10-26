import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/realtime/domain/entities/company_invalidation_resource.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_cubit.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_state.dart';
import '../../../../core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/policies/payments_permission_policy.dart';
import '../cubit/payments_cubit.dart';
import '../cubit/payments_state.dart';
import '../helpers/payments_failure_message.dart';

/// List-only invalidation. The existing invoice broadcast continues to own
/// statements, invoice references, Dashboard and Open Invoices projections.
final class PaymentsRealtimeBoundary extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final Widget child;

  const PaymentsRealtimeBoundary({
    required this.currentCompanyContext,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!PaymentsPermissionPolicy.canViewPayments(currentCompanyContext.role)) {
      return child;
    }

    return CompanyResourceInvalidationBoundary(
      companyId: currentCompanyContext.companyId,
      resources: const {CompanyInvalidationResource.payments},
      onInvalidate: (context) =>
          context.read<PaymentsCubit>().refreshPaymentsFromRealtime(),
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
          BlocListener<PaymentsCubit, PaymentsState>(
            listenWhen: (previous, current) =>
                current is PaymentsLoaded &&
                current.paymentsRefreshFailure != null &&
                (previous is! PaymentsLoaded ||
                    previous.paymentsRefreshFailure?.code !=
                        current.paymentsRefreshFailure?.code),
            listener: (context, current) {
              if (current is! PaymentsLoaded) return;
              final failure = current.paymentsRefreshFailure;
              if (failure == null) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(paymentsFailureMessage(context, failure))),
              );
            },
          ),
        ],
        child: child,
      ),
    );
  }
}
