import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../../audit/presentation/localization/audit_display_localizations_x.dart';
import '../cubit/trips_state.dart';
import '../localization/trips_localizations_x.dart';
import 'trip_details_helpers.dart';
import 'trip_details_shared_widgets.dart';

class TripAccountabilitySection extends StatelessWidget {
  final TripsLoaded? state;

  const TripAccountabilitySection({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state == null || state!.isActivityLoading) {
      return TripDetailsCard(children: [Text(l10n.tripLoadingActivity)]);
    }

    final failure = state!.activityFailure;
    if (failure != null) return TripDetailsFailureCard(failure: failure);

    final activity = state!.selectedTripActivity;
    final created = firstCreatedTripAuditLog(activity);
    final latest = activity.isEmpty ? null : activity.first;

    return TripDetailsCard(
      children: [
        TripDetailRow(
          label: l10n.tripCreatedBy,
          value: created?.actorDisplayName ?? l10n.tripUnknownUser,
        ),
        TripDetailRow(
          label: l10n.tripCreatedRole,
          value: l10n.auditRoleDisplayLabel(created?.actorRole),
        ),
        TripDetailRow(
          label: l10n.tripCreatedAt,
          value: formatTripDateTime(created?.createdAt, l10n.tripEmptyValue),
        ),
        TripDetailRow(
          label: l10n.tripLastActivityBy,
          value: latest?.actorDisplayName ?? l10n.tripUnknownUser,
        ),
        TripDetailRow(
          label: l10n.tripLastActivityRole,
          value: l10n.auditRoleDisplayLabel(latest?.actorRole),
        ),
        TripDetailRow(
          label: l10n.tripLastActivityAt,
          value: formatTripDateTime(latest?.createdAt, l10n.tripEmptyValue),
        ),
      ],
    );
  }
}
