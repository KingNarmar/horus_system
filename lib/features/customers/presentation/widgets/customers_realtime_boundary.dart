import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/realtime/di/realtime_dependencies.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_cubit.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_state.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/policies/customers_permission_policy.dart';
import '../cubit/customers_cubit.dart';

/// Customers-only pilot. The stream and channel are owned by this subtree
/// and disposed when the user leaves Customers or changes company.
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

    return BlocProvider<CompanyRealtimeCubit>(
      key: ValueKey(
        '${currentCompanyContext.companyId}:${currentCompanyContext.role.name}',
      ),
      create: (_) => RealtimeDependencies.createCubit()
        ..watchCompany(currentCompanyContext.companyId),
      child: MultiBlocListener(
        listeners: [
          BlocListener<CompanyRealtimeCubit, CompanyRealtimeState>(
            listenWhen: (previous, current) =>
                current.companyId == currentCompanyContext.companyId &&
                previous.customersRevision != current.customersRevision,
            listener: (context, _) => unawaited(
              context.read<CustomersCubit>().refreshCustomers(
                currentCompanyContext,
              ),
            ),
          ),
          BlocListener<CompanyRealtimeCubit, CompanyRealtimeState>(
            listenWhen: (previous, current) =>
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
          ),
        ],
        child: child,
      ),
    );
  }
}
