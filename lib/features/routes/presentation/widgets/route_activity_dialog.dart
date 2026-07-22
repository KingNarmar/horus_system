import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../audit/presentation/helpers/audit_change_builder.dart';
import '../../domain/entities/route_entity.dart';
import '../cubit/routes_state.dart';
import '../localization/routes_localizations_x.dart';

class RouteDetailsDialog extends StatelessWidget {
  final RouteEntity route;
  final RoutesLoaded? state;

  const RouteDetailsDialog({
    required this.route,
    required this.state,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final activity = state?.selectedRoute?.id == route.id
        ? state!.selectedRouteActivity
        : const <AuditLog>[];

    final isLoading =
        state?.selectedRoute?.id == route.id &&
        (state?.isActivityLoading ?? false);

    final failure = state?.selectedRoute?.id == route.id
        ? state?.activityFailure
        : null;

    final createdLog = _findOldestAction(activity, AuditAction.created.value);
    final latestLog = activity.isEmpty ? null : activity.first;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.detailsDialogMaxWidth,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.routeDetailsTitle(route.displayName),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(AppIcons.clear),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _RouteDetailsSection(
                title: l10n.routeBasicInfo,
                children: [
                  _RouteDetailRow(
                    label: l10n.loadingLocationLabel,
                    value: route.loadingLocation,
                  ),
                  _RouteDetailRow(
                    label: l10n.unloadingLocationLabel,
                    value: route.unloadingLocation,
                  ),
                  _RouteDetailRow(
                    label: l10n.governorateFromLabel,
                    value: _optional(route.governorateFrom, l10n),
                  ),
                  _RouteDetailRow(
                    label: l10n.governorateToLabel,
                    value: _optional(route.governorateTo, l10n),
                  ),
                  _RouteDetailRow(
                    label: l10n.defaultFreightPriceLabel,
                    value:
                        route.defaultFreightPrice?.toStringAsFixed(2) ??
                        l10n.routeEmptyValue,
                  ),
                  _RouteDetailRow(
                    label: l10n.routeNotesLabel,
                    value: _optional(route.notes, l10n),
                  ),
                  _RouteDetailRow(
                    label: l10n.routeStatusHeader,
                    value: route.isActive
                        ? l10n.activeStatusLabel
                        : l10n.inactiveStatusLabel,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _RouteDetailsSection(
                title: l10n.routeAccountability,
                children: [
                  _RouteDetailRow(
                    label: l10n.routeCreatedBy,
                    value: _actorName(createdLog, l10n),
                  ),
                  _RouteDetailRow(
                    label: l10n.routeCreatedRole,
                    value: l10n.routeAuditRoleLabel(createdLog?.actorRole),
                  ),
                  _RouteDetailRow(
                    label: l10n.routeCreatedAt,
                    value: createdLog == null
                        ? l10n.routeNotAvailable
                        : _formatDateTime(context, createdLog.createdAt),
                  ),
                  _RouteDetailRow(
                    label: l10n.routeLastActivityBy,
                    value: _actorName(latestLog, l10n),
                  ),
                  _RouteDetailRow(
                    label: l10n.routeLastActivityRole,
                    value: l10n.routeAuditRoleLabel(latestLog?.actorRole),
                  ),
                  _RouteDetailRow(
                    label: l10n.routeLastActivityAt,
                    value: latestLog == null
                        ? l10n.routeNotAvailable
                        : _formatDateTime(context, latestLog.createdAt),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _RouteDetailsSection(
                title: l10n.routeActivityTimeline,
                children: [
                  if (isLoading)
                    Row(
                      children: [
                        const SizedBox(
                          height: AppSizes.iconSm,
                          width: AppSizes.iconSm,
                          child: CircularProgressIndicator(
                            strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(l10n.routeLoadingActivity),
                      ],
                    )
                  else if (failure != null)
                    Text(l10n.localizedErrorMessage(failure))
                  else if (activity.isEmpty)
                    Text(l10n.routeNoActivityFound)
                  else
                    ...activity.map(
                      (log) => _RouteActivityTimelineItem(log: log),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  AuditLog? _findOldestAction(List<AuditLog> logs, String action) {
    for (final log in logs.reversed) {
      if (log.action.value == action) return log;
    }
    return null;
  }

  String _actorName(AuditLog? log, AppLocalizations l10n) {
    final name = log?.actorDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;

    final email = log?.actorEmail?.trim();
    if (email != null && email.isNotEmpty) return email;

    return l10n.routeUnknownUser;
  }

  String _optional(String? value, AppLocalizations l10n) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty
        ? l10n.routeEmptyValue
        : normalized;
  }
}

class _RouteActivityTimelineItem extends StatelessWidget {
  final AuditLog log;

  const _RouteActivityTimelineItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    const visibleKeys = [
      'loading_location',
      'unloading_location',
      'governorate_from',
      'governorate_to',
      'default_freight_price',
      'notes',
      'is_active',
    ];

    final changes = AuditChangeBuilder.buildChanges(
      log: log,
      visibleKeys: visibleKeys,
      fieldLabelBuilder: l10n.routeAuditFieldLabel,
      valueLabelBuilder: l10n.routeAuditValueLabel,
    );

    final actorName = log.actorDisplayName?.trim().isNotEmpty == true
        ? log.actorDisplayName!.trim()
        : (log.actorEmail?.trim().isNotEmpty == true
              ? log.actorEmail!.trim()
              : l10n.routeUnknownUser);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: Icon(AppIcons.auditHistory, size: AppSizes.iconSm),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.routeAuditActionLabel(log.action.value),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  l10n.routeAuditTimelineHeader(
                    actorName,
                    l10n.routeAuditRoleLabel(log.actorRole),
                    _formatDateTime(context, log.createdAt),
                  ),
                ),
                if (changes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.routeChanges,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...changes.map(
                    (change) => Text(
                      l10n.routeAuditChangeLine(
                        change.label,
                        change.oldValue,
                        change.newValue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteDetailsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _RouteDetailsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _RouteDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _RouteDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _formatDateTime(BuildContext context, DateTime value) {
  final localValue = value.toLocal();
  final materialLocalizations = MaterialLocalizations.of(context);
  final date = materialLocalizations.formatMediumDate(localValue);
  final time = TimeOfDay.fromDateTime(localValue).format(context);
  return '$date, $time';
}
