import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/realtime/domain/entities/company_invalidation_resource.dart';
import '../../../../core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/policies/payments_permission_policy.dart';
import '../cubit/payments_cubit.dart';
import '../cubit/payments_state.dart';

/// R4.5 only: keep invoice references in the Payments screen current.
/// Direct payment create/status broadcasts remain owned by R4.6.
final class PaymentInvoiceReferencesRealtimeBoundary extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final Widget child;

  const PaymentInvoiceReferencesRealtimeBoundary({
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
      resources: const {CompanyInvalidationResource.paymentFormLookups},
      onInvalidate: (context) => context
          .read<PaymentsCubit>()
          .refreshInvoiceReferencesFromRealtime(),
      child: BlocListener<PaymentsCubit, PaymentsState>(
        listenWhen: (previous, current) =>
            current is PaymentsLoaded &&
            current.invoiceReferencesRefreshFailure != null &&
            (previous is! PaymentsLoaded ||
                previous.invoiceReferencesRefreshFailure?.code !=
                    current.invoiceReferencesRefreshFailure?.code),
        listener: (context, current) {
          if (current is! PaymentsLoaded) return;
          final failure = current.invoiceReferencesRefreshFailure;
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
