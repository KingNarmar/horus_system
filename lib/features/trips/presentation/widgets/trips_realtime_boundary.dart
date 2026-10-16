import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/realtime/domain/entities/company_invalidation_resource.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_cubit.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_state.dart';
import '../../../../core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/policies/trips_permission_policy.dart';
import '../cubit/trips_cubit.dart';
import '../cubit/trips_state.dart';

/// Mounted Trips consumes Trip mutations and independent master-data lookups.
/// Mutations refresh authoritative state without resetting open forms.
final class TripsRealtimeBoundary extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final Widget child;

  const TripsRealtimeBoundary({
    required this.currentCompanyContext,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!TripsPermissionPolicy.canViewTrips(currentCompanyContext.role)) {
      return child;
    }

    return CompanyResourceInvalidationBoundary(
      companyId: currentCompanyContext.companyId,
      resources: const {CompanyInvalidationResource.trips},
      onInvalidate: (context) =>
          context.read<TripsCubit>().refreshTripsFromRealtime(),
      child: CompanyResourceInvalidationBoundary(
        companyId: currentCompanyContext.companyId,
        resources: const {CompanyInvalidationResource.tripFormLookups},
        onInvalidate: (context) {
          if (!TripsPermissionPolicy.canManageTrips(currentCompanyContext.role)) {
            return Future<void>.value();
          }
          final cubit = context.read<TripsCubit>();
          final current = cubit.state;
          if (current is! TripsLoaded ||
              (current.formLookups == null && !current.isFormLookupsLoading)) {
            return Future<void>.value();
          }
          return cubit.refreshTripFormLookups();
        },
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
            BlocListener<TripsCubit, TripsState>(
              listenWhen: (previous, current) =>
                  current is TripsLoaded &&
                  current.routeReferenceRefreshFailure != null &&
                  (previous is! TripsLoaded ||
                      previous.routeReferenceRefreshFailure?.code !=
                          current.routeReferenceRefreshFailure?.code),
              listener: (context, state) {
                if (state is TripsLoaded &&
                    state.routeReferenceRefreshFailure != null) {
                  _showFailure(context, state.routeReferenceRefreshFailure!);
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
