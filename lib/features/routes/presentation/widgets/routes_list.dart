import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/route_entity.dart';
import '../localization/routes_localizations_x.dart';

class RoutesList extends StatelessWidget {
  final List<RouteEntity> routes;
  final bool canManageRoutes;
  final bool Function(String id) isActiveStateChanging;
  final ValueChanged<RouteEntity> onViewDetails;
  final ValueChanged<RouteEntity> onEdit;
  final ValueChanged<RouteEntity> onDeactivate;
  final ValueChanged<RouteEntity> onReactivate;

  const RoutesList({
    required this.routes,
    required this.canManageRoutes,
    required this.isActiveStateChanging,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return _RoutesTable(
            routes: routes,
            canManageRoutes: canManageRoutes,
            isActiveStateChanging: isActiveStateChanging,
            onViewDetails: onViewDetails,
            onEdit: onEdit,
            onDeactivate: onDeactivate,
            onReactivate: onReactivate,
          );
        }

        return _RoutesCards(
          routes: routes,
          canManageRoutes: canManageRoutes,
          isActiveStateChanging: isActiveStateChanging,
          onViewDetails: onViewDetails,
          onEdit: onEdit,
          onDeactivate: onDeactivate,
          onReactivate: onReactivate,
        );
      },
    );
  }
}

class _RoutesTable extends StatelessWidget {
  final List<RouteEntity> routes;
  final bool canManageRoutes;
  final bool Function(String id) isActiveStateChanging;
  final ValueChanged<RouteEntity> onViewDetails;
  final ValueChanged<RouteEntity> onEdit;
  final ValueChanged<RouteEntity> onDeactivate;
  final ValueChanged<RouteEntity> onReactivate;

  const _RoutesTable({
    required this.routes,
    required this.canManageRoutes,
    required this.isActiveStateChanging,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.routeLoadingHeader)),
            DataColumn(label: Text(l10n.routeUnloadingHeader)),
            DataColumn(label: Text(l10n.routeGovernoratesHeader)),
            DataColumn(label: Text(l10n.routeDefaultPriceHeader)),
            DataColumn(label: Text(l10n.routeStatusHeader)),
            const DataColumn(label: SizedBox(width: 132)),
          ],
          rows: routes.map((route) {
            final isChanging = isActiveStateChanging(route.id);

            return DataRow(
              cells: [
                DataCell(Text(route.loadingLocation)),
                DataCell(Text(route.unloadingLocation)),
                DataCell(Text(_governoratesText(route, l10n.emptyValue))),
                DataCell(Text(_priceText(route, l10n.emptyValue))),
                DataCell(_RouteStatusChip(route: route)),
                DataCell(
                  SizedBox(
                    width: 132,
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: _RouteActions(
                        route: route,
                        canManageRoutes: canManageRoutes,
                        isChanging: isChanging,
                        onViewDetails: onViewDetails,
                        onEdit: onEdit,
                        onDeactivate: onDeactivate,
                        onReactivate: onReactivate,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RoutesCards extends StatelessWidget {
  final List<RouteEntity> routes;
  final bool canManageRoutes;
  final bool Function(String id) isActiveStateChanging;
  final ValueChanged<RouteEntity> onViewDetails;
  final ValueChanged<RouteEntity> onEdit;
  final ValueChanged<RouteEntity> onDeactivate;
  final ValueChanged<RouteEntity> onReactivate;

  const _RoutesCards({
    required this.routes,
    required this.canManageRoutes,
    required this.isActiveStateChanging,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: routes.map((route) {
        final isChanging = isActiveStateChanging(route.id);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  route.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _InfoText(
                      label: l10n.routeGovernoratesHeader,
                      value: _governoratesText(route, l10n.emptyValue),
                    ),
                    _InfoText(
                      label: l10n.routeDefaultPriceHeader,
                      value: _priceText(route, l10n.emptyValue),
                    ),
                    _RouteStatusChip(route: route),
                  ],
                ),
                if (route.notes != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(route.notes!),
                ],
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _RouteActions(
                    route: route,
                    canManageRoutes: canManageRoutes,
                    isChanging: isChanging,
                    onViewDetails: onViewDetails,
                    onEdit: onEdit,
                    onDeactivate: onDeactivate,
                    onReactivate: onReactivate,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InfoText extends StatelessWidget {
  final String label;
  final String value;

  const _InfoText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text('$label: $value');
  }
}

class _RouteStatusChip extends StatelessWidget {
  final RouteEntity route;

  const _RouteStatusChip({required this.route});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Chip(
      label: Text(
        route.isActive ? l10n.activeStatusLabel : l10n.inactiveStatusLabel,
      ),
    );
  }
}

class _RouteActions extends StatelessWidget {
  final RouteEntity route;
  final bool canManageRoutes;
  final bool isChanging;
  final ValueChanged<RouteEntity> onViewDetails;
  final ValueChanged<RouteEntity> onEdit;
  final ValueChanged<RouteEntity> onDeactivate;
  final ValueChanged<RouteEntity> onReactivate;

  const _RouteActions({
    required this.route,
    required this.canManageRoutes,
    required this.isChanging,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIconButton(
          tooltip: l10n.routeViewDetails,
          onPressed: () => onViewDetails(route),
          icon: const Icon(AppIcons.view),
        ),
        if (canManageRoutes) ...[
          _ActionIconButton(
            tooltip: l10n.editButton,
            onPressed: isChanging ? null : () => onEdit(route),
            icon: const Icon(AppIcons.edit),
          ),
          if (route.isActive)
            _ActionIconButton(
              tooltip: l10n.routeDeactivateButton,
              onPressed: isChanging ? null : () => onDeactivate(route),
              icon: isChanging
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(AppIcons.deactivate),
            )
          else
            _ActionIconButton(
              tooltip: l10n.routeReactivateButton,
              onPressed: isChanging ? null : () => onReactivate(route),
              icon: isChanging
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(AppIcons.reactivate),
            ),
        ],
      ],
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;

  const _ActionIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: icon,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    );
  }
}

String _governoratesText(RouteEntity route, String emptyValue) {
  final from = route.governorateFrom?.trim();
  final to = route.governorateTo?.trim();

  if ((from == null || from.isEmpty) && (to == null || to.isEmpty)) {
    return emptyValue;
  }

  return '${from == null || from.isEmpty ? emptyValue : from} -> ${to == null || to.isEmpty ? emptyValue : to}';
}

String _priceText(RouteEntity route, String emptyValue) {
  final price = route.defaultFreightPrice;
  if (price == null) return emptyValue;

  final text = price.toStringAsFixed(2);
  return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
}
