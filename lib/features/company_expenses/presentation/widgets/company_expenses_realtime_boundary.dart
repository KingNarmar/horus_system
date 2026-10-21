import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/realtime/domain/entities/company_invalidation_resource.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_cubit.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_state.dart';
import '../../../../core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/policies/company_expenses_permission_policy.dart';
import '../cubit/company_expenses_cubit.dart';
import '../cubit/company_expenses_state.dart';

/// Only a mounted, finance-authorized Company Expenses view refreshes.
final class CompanyExpensesRealtimeBoundary extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final Widget child;

  const CompanyExpensesRealtimeBoundary({
    required this.currentCompanyContext,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!CompanyExpensesPermissionPolicy.canViewCompanyExpenses(
      currentCompanyContext.role,
    )) {
      return child;
    }
    return CompanyResourceInvalidationBoundary(
      companyId: currentCompanyContext.companyId,
      resources: const {CompanyInvalidationResource.companyExpenses},
      onInvalidate: (context) => context
          .read<CompanyExpensesCubit>()
          .refreshCompanyExpensesFromRealtime(),
      child: CompanyResourceInvalidationBoundary(
        companyId: currentCompanyContext.companyId,
        resources: const {CompanyInvalidationResource.companyExpenseLookups},
        onInvalidate: (context) => context
            .read<CompanyExpensesCubit>()
            .refreshCompanyExpenseReferencesFromRealtime(),
        child: MultiBlocListener(
          listeners: [
            BlocListener<CompanyRealtimeCubit, CompanyRealtimeState>(
              listenWhen: (previous, current) =>
                  current.companyId == currentCompanyContext.companyId &&
                  current.failure != null &&
                  previous.failure?.code != current.failure?.code,
              listener: (context, current) {
                if (current.failure case final Failure failure) {
                  _showFailure(context, failure);
                }
              },
            ),
            BlocListener<CompanyExpensesCubit, CompanyExpensesState>(
              listenWhen: (previous, current) =>
                  current is CompanyExpensesLoaded &&
                  current.realtimeRefreshFailure != null &&
                  (previous is! CompanyExpensesLoaded ||
                      previous.realtimeRefreshFailure?.code !=
                          current.realtimeRefreshFailure?.code),
              listener: (context, current) {
                if (current is CompanyExpensesLoaded &&
                    current.realtimeRefreshFailure != null) {
                  _showFailure(context, current.realtimeRefreshFailure!);
                }
              },
            ),
          ],
          child: child,
        ),
      ),
    );
  }

  void _showFailure(BuildContext context, Failure failure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.localizedErrorMessage(failure))),
    );
  }
}
