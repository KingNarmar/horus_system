import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../audit/presentation/localization/audit_display_localizations_x.dart';
import '../cubit/trips_state.dart';
import '../localization/trips_localizations_x.dart';
import 'trip_details_helpers.dart';
import 'trip_details_shared_widgets.dart';

class TripActivityTimelineSection extends StatelessWidget {
  final TripsLoaded? state;

  const TripActivityTimelineSection({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state == null || state!.isActivityLoading) {
      return TripDetailsCard(children: [Text(l10n.tripLoadingActivity)]);
    }

    final failure = state!.activityFailure;
    if (failure != null) return TripDetailsFailureCard(failure: failure);

    final activity = state!.selectedTripActivity;
    if (activity.isEmpty) {
      return TripDetailsCard(children: [Text(l10n.tripNoActivityFound)]);
    }

    return Column(
      children: [
        for (final log in activity) TripActivityTimelineItem(log: log),
      ],
    );
  }
}

class TripActivityTimelineItem extends StatelessWidget {
  final AuditLog log;

  const TripActivityTimelineItem({required this.log, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actor = log.actorDisplayName ?? l10n.tripUnknownUser;
    final role = l10n.auditRoleDisplayLabel(log.actorRole);
    final date = formatTripDateTime(log.createdAt, l10n.tripEmptyValue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(AppIcons.auditHistory),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    localizedTripAuditActionTitle(context, log),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.tripAuditTimelineHeader(actor, role, date)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(localizedTripAuditDescription(context, log)),
                  ..._changeLines(context, log),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _changeLines(BuildContext context, AuditLog log) {
    if (!shouldShowTripAuditChanges(log)) return const [];

    final l10n = context.l10n;
    final previous = log.oldValues ?? const <String, Object?>{};
    final next = log.newValues ?? const <String, Object?>{};
    final visibleKeys = visibleTripAuditChangeKeys(log);

    if (visibleKeys.isEmpty) return const [];

    final showDetails = shouldShowTripAuditDetails(log);

    return [
      const SizedBox(height: AppSpacing.sm),
      Text(
        showDetails ? l10n.tripAuditDetails : l10n.tripChanges,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: AppSpacing.xs),
      ...visibleKeys.map((key) {
        final previousValue = safeTripAuditValue(previous[key]);
        final nextValue = safeTripAuditValue(next[key]);

        if (showDetails) {
          return Text(
            l10n.tripAuditDetailLine(
              l10n.tripAuditFieldLabel(key),
              l10n.tripAuditValueLabel(key, nextValue),
            ),
          );
        }

        return Text(
          l10n.tripAuditChangeLine(
            l10n.tripAuditFieldLabel(key),
            l10n.tripAuditValueLabel(key, previousValue),
            l10n.tripAuditValueLabel(key, nextValue),
          ),
        );
      }),
    ];
  }
}
