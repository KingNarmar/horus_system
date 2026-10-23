import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/realtime/domain/entities/company_invalidation_resource.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_cubit.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_state.dart';
import '../../../../core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/policies/driver_settlements_permission_policy.dart';
import '../cubit/driver_settlements_cubit.dart';
import '../cubit/driver_settlements_state.dart';

/// A mounted, finance-authorized consumer of the company's shared stream.
final class DriverSettlementsRealtimeBoundary extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final Widget child;

  const DriverSettlementsRealtimeBoundary({
    required this.currentCompanyContext,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!DriverSettlementsPermissionPolicy.canViewDriverSettlements(
      currentCompanyContext.role,
    )) {
      return child;
    }
    return CompanyResourceInvalidationBoundary(
      companyId: currentCompanyContext.companyId,
      resources: const {CompanyInvalidationResource.driverSettlements},
      onInvalidate: (context) => context
          .read<DriverSettlementsCubit>()
          .refreshDriverSettlementsFromRealtime(),
      child: CompanyResourceInvalidationBoundary(
        companyId: currentCompanyContext.companyId,
        resources: const {
          CompanyInvalidationResource.driverSettlementDriverOptions,
        },
        onInvalidate: (context) => context
            .read<DriverSettlementsCubit>()
            .refreshSettlementDriverOptionsFromRealtime(),
        child: CompanyResourceInvalidationBoundary(
          companyId: currentCompanyContext.companyId,
          resources: const {CompanyInvalidationResource.settlementSources},
          onInvalidate: (context) async {
            context.read<DriverSettlementsCubit>().invalidatePreview();
          },
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
                      content: Text(
                        context.l10n.localizedErrorMessage(failure),
                      ),
                    ),
                  );
                },
              ),
              BlocListener<DriverSettlementsCubit, DriverSettlementsState>(
                listenWhen: (previous, current) =>
                    current is DriverSettlementsLoaded &&
                    current.realtimeRefreshFailure != null &&
                    (previous is! DriverSettlementsLoaded ||
                        previous.realtimeRefreshFailure?.code !=
                            current.realtimeRefreshFailure?.code),
                listener: (context, current) {
                  if (current is! DriverSettlementsLoaded) return;
                  final failure = current.realtimeRefreshFailure;
                  if (failure == null) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.localizedErrorMessage(failure),
                      ),
                    ),
                  );
                },
              ),
            ],
            child: child,
          ),
        ),
      ),
    );
  }
}
