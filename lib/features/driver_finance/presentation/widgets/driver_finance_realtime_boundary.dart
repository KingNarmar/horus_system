import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/realtime/domain/entities/company_invalidation_resource.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_cubit.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_state.dart';
import '../../../../core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/policies/driver_finance_permission_policy.dart';
import '../cubit/driver_finance_cubit.dart';

/// Only an authorized, mounted Driver Finance view consumes financial hints.
final class DriverFinanceRealtimeBoundary extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final Widget child;

  const DriverFinanceRealtimeBoundary({
    required this.currentCompanyContext,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!DriverFinancePermissionPolicy.canViewDriverFinance(
      currentCompanyContext.role,
    )) {
      return child;
    }

    return CompanyResourceInvalidationBoundary(
      companyId: currentCompanyContext.companyId,
      resources: const {
        CompanyInvalidationResource.driverFinance,
        CompanyInvalidationResource.driverBalances,
        CompanyInvalidationResource.driverFinanceTripOptions,
      },
      onInvalidate: (context) =>
          context.read<DriverFinanceCubit>().refreshDriverFinanceFromRealtime(),
      child: CompanyResourceInvalidationBoundary(
        companyId: currentCompanyContext.companyId,
        resources: const {CompanyInvalidationResource.drivers},
        onInvalidate: (context) => context
            .read<DriverFinanceCubit>()
            .refreshDriverReferencesFromRealtime(),
        child: BlocListener<CompanyRealtimeCubit, CompanyRealtimeState>(
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
          child: child,
        ),
      ),
    );
  }
}
