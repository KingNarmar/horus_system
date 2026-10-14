import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/realtime/domain/entities/company_invalidation_resource.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_cubit.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_state.dart';
import '../../../../core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/policies/customers_permission_policy.dart';
import '../cubit/customers_cubit.dart';

/// R1 Customers behavior through the shared company-session subscription.
/// This boundary owns only its visible resource interest, not the channel.
final class CustomersRealtimeBoundary extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final Widget child;

  const CustomersRealtimeBoundary({
    required this.currentCompanyContext,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!CustomersPermissionPolicy.canViewCustomers(
      currentCompanyContext.role,
    )) {
      return child;
    }

    return CompanyResourceInvalidationBoundary(
      companyId: currentCompanyContext.companyId,
      resources: const {CompanyInvalidationResource.customers},
      onInvalidate: (context) => context.read<CustomersCubit>().refreshCustomers(
        currentCompanyContext,
      ),
      child: BlocListener<CompanyRealtimeCubit, CompanyRealtimeState>(
        listenWhen: (previous, current) =>
            current.companyId == currentCompanyContext.companyId &&
            current.failure != null &&
            previous.failure?.code != current.failure?.code,
        listener: (context, state) {
          final failure = state.failure;
          if (failure == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.localizedErrorMessage(failure)),
            ),
          );
        },
        child: child,
      ),
    );
  }
}
