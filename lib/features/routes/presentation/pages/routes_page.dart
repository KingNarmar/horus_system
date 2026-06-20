import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/widgets/active_state_confirmation_dialog.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/route_entity.dart';
import '../cubit/routes_cubit.dart';
import '../cubit/routes_state.dart';
import '../localization/routes_localizations_x.dart';
import '../widgets/route_activity_dialog.dart';
import '../widgets/route_form_dialog.dart';
import '../widgets/routes_filters.dart';
import '../widgets/routes_list.dart';

class RoutesPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const RoutesPage({required this.currentCompanyContext, super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  @override
  void initState() {
    super.initState();
    context.read<RoutesCubit>().loadRoutes(widget.currentCompanyContext);
  }

  Future<void> _showRouteForm({RouteEntity? route}) {
    final cubit = context.read<RoutesCubit>();
    final l10n = context.l10n;

    return showDialog<void>(
      context: context,
      builder: (_) {
        return RouteFormDialog(
          title: route == null ? l10n.addRouteTitle : l10n.editRouteTitle,
          route: route,
          onSubmit: (data) {
            return cubit.saveRoute(
              route: route,
              loadingLocation: data.loadingLocation,
              unloadingLocation: data.unloadingLocation,
              governorateFrom: data.governorateFrom,
              governorateTo: data.governorateTo,
              defaultFreightPrice: data.defaultFreightPrice,
              notes: data.notes,
            );
          },
        );
      },
    );
  }

  Future<void> _openRouteDetails(RouteEntity route) async {
    final cubit = context.read<RoutesCubit>();

    cubit.loadRouteActivity(route);

    await showDialog<void>(
      context: context,
      builder: (_) {
        return BlocProvider.value(
          value: cubit,
          child: BlocBuilder<RoutesCubit, RoutesState>(
            builder: (context, state) {
              return RouteDetailsDialog(
                route: route,
                state: state is RoutesLoaded ? state : null,
              );
            },
          ),
        );
      },
    );

    cubit.clearRouteActivity();
  }

  Future<void> _deactivateRoute(RouteEntity route) async {
    final cubit = context.read<RoutesCubit>();
    final l10n = context.l10n;

    final confirmed = await showActiveStateConfirmationDialog(
      context: context,
      title: l10n.confirmRouteDeactivateTitle,
      message: l10n.confirmRouteDeactivateMessage,
      confirmLabel: l10n.routeDeactivateButton,
      cancelLabel: l10n.cancelButton,
    );

    if (!confirmed) return;

    await cubit.deactivateRoute(route);
  }

  Future<void> _reactivateRoute(RouteEntity route) async {
    final cubit = context.read<RoutesCubit>();
    final l10n = context.l10n;

    final confirmed = await showActiveStateConfirmationDialog(
      context: context,
      title: l10n.confirmRouteReactivateTitle,
      message: l10n.confirmRouteReactivateMessage,
      confirmLabel: l10n.routeReactivateButton,
      cancelLabel: l10n.cancelButton,
    );

    if (!confirmed) return;

    await cubit.reactivateRoute(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<RoutesCubit, RoutesState>(
      listener: (context, state) {
        if (state is RoutesFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.localizedErrorMessage(state.failure))),
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RoutesHeader(
              canAdd: state is RoutesLoaded && state.canManageRoutes,
              onAddPressed: () => _showRouteForm(),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state is RoutesInitial || state is RoutesLoading)
              const Center(child: CircularProgressIndicator())
            else if (state is RoutesLoaded)
              _RoutesLoadedBody(
                state: state,
                onViewDetails: _openRouteDetails,
                onEdit: (route) => _showRouteForm(route: route),
                onDeactivate: _deactivateRoute,
                onReactivate: _reactivateRoute,
              )
            else if (state is RoutesFailure)
              _RoutesFailureView(
                failureText: l10n.localizedErrorMessage(state.failure),
                onRetry: () {
                  context.read<RoutesCubit>().loadRoutes(
                    widget.currentCompanyContext,
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _RoutesHeader extends StatelessWidget {
  final bool canAdd;
  final VoidCallback onAddPressed;

  const _RoutesHeader({required this.canAdd, required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.routesTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (canAdd)
          FilledButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(AppIcons.add),
            label: Text(l10n.addRouteButton),
          ),
      ],
    );
  }
}

class _RoutesLoadedBody extends StatelessWidget {
  final RoutesLoaded state;
  final ValueChanged<RouteEntity> onViewDetails;
  final ValueChanged<RouteEntity> onEdit;
  final ValueChanged<RouteEntity> onDeactivate;
  final ValueChanged<RouteEntity> onReactivate;

  const _RoutesLoadedBody({
    required this.state,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    final l10n = context.l10n;
    final routes = state.routes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoutesFilters(
          statusFilter: state.statusFilter,
          onSearchChanged: cubit.setSearchQuery,
          onStatusFilterChanged: cubit.setStatusFilter,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (state.allRoutes.isEmpty)
          _EmptyRoutesCard(text: l10n.noRoutesFound)
        else if (routes.isEmpty)
          _EmptyRoutesCard(text: l10n.noRoutesMatchFilters)
        else
          RoutesList(
            routes: routes,
            canManageRoutes: state.canManageRoutes,
            isActiveStateChanging: state.isActiveStateChanging,
            onViewDetails: onViewDetails,
            onEdit: onEdit,
            onDeactivate: onDeactivate,
            onReactivate: onReactivate,
          ),
      ],
    );
  }
}

class _EmptyRoutesCard extends StatelessWidget {
  final String text;

  const _EmptyRoutesCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(text),
      ),
    );
  }
}

class _RoutesFailureView extends StatelessWidget {
  final String failureText;
  final VoidCallback onRetry;

  const _RoutesFailureView({required this.failureText, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Text(failureText),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retryButton)),
          ],
        ),
      ),
    );
  }
}
