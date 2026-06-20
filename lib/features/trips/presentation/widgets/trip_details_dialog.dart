import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../cubit/trips_state.dart';
import '../localization/trips_localizations_x.dart';
import 'trip_accountability_section.dart';
import 'trip_activity_timeline_section.dart';
import 'trip_basic_info_section.dart';
import 'trip_details_shared_widgets.dart';
import 'trip_status_history_section.dart';

class TripDetailsDialog extends StatelessWidget {
  final TripEntity trip;
  final TripsLoaded? state;

  const TripDetailsDialog({required this.trip, required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mediaSize = MediaQuery.of(context).size;
    final detailsTrip = state?.selectedTrip?.id == trip.id
        ? state!.selectedTrip!
        : trip;

    final dialogWidth = (mediaSize.width - AppSpacing.xxl).clamp(
      320.0,
      820.0,
    ).toDouble();

    final dialogHeight = (mediaSize.height - AppSpacing.xxl).clamp(
      420.0,
      760.0,
    ).toDouble();

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TripDetailsHeader(title: l10n.tripDetailsTitle(detailsTrip.displayName)),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TripDetailsSectionTitle(text: l10n.tripBasicInfo),
                    const SizedBox(height: AppSpacing.sm),
                    TripBasicInfoSection(trip: detailsTrip),
                    const SizedBox(height: AppSpacing.lg),
                    TripDetailsSectionTitle(text: l10n.tripAccountability),
                    const SizedBox(height: AppSpacing.sm),
                    TripAccountabilitySection(state: state),
                    const SizedBox(height: AppSpacing.lg),
                    TripDetailsSectionTitle(text: l10n.tripStatusHistoryTitle),
                    const SizedBox(height: AppSpacing.sm),
                    TripStatusHistorySection(state: state),
                    const SizedBox(height: AppSpacing.lg),
                    TripDetailsSectionTitle(text: l10n.tripActivityTimeline),
                    const SizedBox(height: AppSpacing.sm),
                    TripActivityTimelineSection(state: state),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.tripCloseButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripDetailsHeader extends StatelessWidget {
  final String title;

  const _TripDetailsHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            tooltip: l10n.tripCloseButton,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}