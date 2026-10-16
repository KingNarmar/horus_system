import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/realtime/domain/entities/company_invalidation_resource.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_cubit.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_state.dart';
import '../../../../core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/policies/routes_permission_policy.dart';
import '../cubit/routes_cubit.dart';
import '../cubit/routes_state.dart';

/// Routes listens through the company-owned session, not Supabase.
final class RoutesRealtimeBoundary extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final Widget child;

  const RoutesRealtimeBoundary({
    required this.currentCompanyContext,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!RoutesPermissionPolicy.canViewRoutes(currentCompanyContext.role)) {
      return child;
    }

    return CompanyResourceInvalidationBoundary(
      companyId: currentCompanyContext.companyId,
      resources: const {CompanyInvalidationResource.routes},
      onInvalidate: (context) =>
          context.read<RoutesCubit>().refreshRoutes(currentCompanyContext),
      child: MultiBlocListener(
        listeners: [
          BlocListener<CompanyRealtimeCubit, CompanyRealtimeState>(
            listenWhen: (previous, current) =>
                current.companyId == currentCompanyContext.companyId &&
                current.failure != null &&
                previous.failure?.code != current.failure?.code,
            listener: (context, state) {
              final failure = state.failure;
              if (failure != null) _showFailure(context, failure);
            },
          ),
          BlocListener<RoutesCubit, RoutesState>(
            listenWhen: (previous, current) =>
                current is RoutesLoaded &&
                current.refreshFailure != null &&
                (previous is! RoutesLoaded ||
                    previous.refreshFailure?.code !=
                        current.refreshFailure?.code),
            listener: (context, state) {
              if (state is RoutesLoaded && state.refreshFailure != null) {
                _showFailure(context, state.refreshFailure!);
              }
            },
          ),
        ],
        child: child,
      ),
    );
  }

  void _showFailure(BuildContext context, Failure failure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.localizedErrorMessage(failure))),
    );
  }
}
