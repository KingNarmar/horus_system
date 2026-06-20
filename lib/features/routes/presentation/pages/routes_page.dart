import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/route_entity.dart';
import '../cubit/routes_cubit.dart';
import '../cubit/routes_state.dart';
import '../localization/routes_localizations_x.dart';
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
              onAddPressed: () => _showRouteForm(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state is RoutesInitial || state is RoutesLoading)
              const Center(child: CircularProgressIndicator())
            else if (state is RoutesLoaded)
              _RoutesLoadedBody(state: state)
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

  Future<void> _showRouteForm(BuildContext context, {RouteEntity? route}) {
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

  const _RoutesLoadedBody({required this.state});

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
            onEdit: (route) => _showRouteForm(context, route: route),
            onDeactivate: (route) => _confirmActiveStateChange(
              context,
              route: route,
              isReactivation: false,
            ),
            onReactivate: (route) => _confirmActiveStateChange(
              context,
              route: route,
              isReactivation: true,
            ),
          ),
      ],
    );
  }

  Future<void> _showRouteForm(
    BuildContext context, {
    required RouteEntity route,
  }) {
    final cubit = context.read<RoutesCubit>();
    final l10n = context.l10n;

    return showDialog<void>(
      context: context,
      builder: (_) {
        return RouteFormDialog(
          title: l10n.editRouteTitle,
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

  Future<void> _confirmActiveStateChange(
    BuildContext context, {
    required RouteEntity route,
    required bool isReactivation,
  }) async {
    final cubit = context.read<RoutesCubit>();
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            isReactivation
                ? l10n.confirmRouteReactivateTitle
                : l10n.confirmRouteDeactivateTitle,
          ),
          content: Text(
            isReactivation
                ? l10n.confirmRouteReactivateMessage
                : l10n.confirmRouteDeactivateMessage,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                isReactivation
                    ? l10n.routeReactivateButton
                    : l10n.routeDeactivateButton,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (isReactivation) {
      await cubit.reactivateRoute(route);
    } else {
      await cubit.deactivateRoute(route);
    }
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
