import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_status_history.dart';
import '../cubit/trips_state.dart';
import '../localization/trips_localizations_x.dart';
import 'trip_details_helpers.dart';
import 'trip_details_shared_widgets.dart';

class TripStatusHistorySection extends StatelessWidget {
  final TripsLoaded? state;

  const TripStatusHistorySection({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state == null || state!.isStatusHistoryLoading) {
      return TripDetailsCard(children: [Text(l10n.tripLoadingStatusHistory)]);
    }

    final failure = state!.statusHistoryFailure;
    if (failure != null) return TripDetailsFailureCard(failure: failure);

    final history = state!.selectedTripStatusHistory;
    if (history.isEmpty) {
      return TripDetailsCard(children: [Text(l10n.tripNoStatusHistoryFound)]);
    }

    return Column(
      children: [for (final item in history) TripStatusHistoryItem(item: item)],
    );
  }
}

class TripStatusHistoryItem extends StatelessWidget {
  final TripStatusHistory item;

  const TripStatusHistoryItem({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.tripStatusHistoryLine(
                item.oldStatus == null
                    ? l10n.tripEmptyValue
                    : l10n.tripStatusLabel(item.oldStatus!),
                l10n.tripStatusLabel(item.newStatus),
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.tripChangedByLine(
                item.changedByName ?? l10n.tripUnknownUser,
                l10n.tripAuditRoleLabel(item.changedByRole),
                formatTripDateTime(item.changedAt, l10n.tripEmptyValue),
              ),
            ),
            if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(item.notes!),
            ],
          ],
        ),
      ),
    );
  }
}
