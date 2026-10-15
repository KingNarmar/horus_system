import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/realtime/domain/entities/company_invalidation_resource.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_cubit.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_state.dart';
import '../../../../core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/policies/fleet_permission_policy.dart';
import '../cubit/fleet_cubit.dart';
import '../cubit/fleet_license_documents_cubit.dart';
import '../cubit/fleet_state.dart';

/// Fleet Assets listens to the company-owned invalidation session, not to
/// Supabase directly. License documents use a separate typed source.
final class FleetRealtimeBoundary extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final Widget child;

  const FleetRealtimeBoundary({
    required this.currentCompanyContext,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!FleetPermissionPolicy.canViewFleet(currentCompanyContext.role)) {
      return child;
    }

    return CompanyResourceInvalidationBoundary(
      companyId: currentCompanyContext.companyId,
      resources: const {CompanyInvalidationResource.fleetLicenseDocuments},
      onInvalidate: (context) async {
        await Future.wait([
          context.read<FleetLicenseDocumentsCubit>().refreshActiveDocument(),
          context.read<FleetCubit>().refreshSelectedAssetActivity(),
        ]);
      },
      child: CompanyResourceInvalidationBoundary(
        companyId: currentCompanyContext.companyId,
        resources: const {CompanyInvalidationResource.fleet},
        onInvalidate: (context) => context
            .read<FleetCubit>()
            .refreshFleetAssets(currentCompanyContext),
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
            BlocListener<FleetCubit, FleetState>(
              listenWhen: (previous, current) =>
                  current is FleetLoaded &&
                  current.refreshFailure != null &&
                  (previous is! FleetLoaded ||
                      previous.refreshFailure?.code !=
                          current.refreshFailure?.code),
              listener: (context, state) {
                if (state is FleetLoaded && state.refreshFailure != null) {
                  _showFailure(context, state.refreshFailure!);
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
