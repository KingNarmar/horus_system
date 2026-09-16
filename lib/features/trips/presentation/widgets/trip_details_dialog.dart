import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../cubit/trips_state.dart';
import 'trip_accountability_section.dart';
import 'trip_activity_timeline_section.dart';
import 'trip_basic_info_section.dart';
import 'trip_details_shared_widgets.dart';
import 'trip_expenses_section.dart';
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
    final financialConfiguration = _financialConfiguration(state);
    final calculatedTotalExpenses = state?.selectedTrip?.id == detailsTrip.id
        ? state?.selectedTripTotalExpenses
        : null;
    final calculatedNetProfit = state?.selectedTrip?.id == detailsTrip.id
        ? state?.selectedTripNetProfit
        : null;
    final businessLocalTimestamps = state?.businessLocalTimestampsFor(
      detailsTrip.id,
    );

    final dialogWidth = (mediaSize.width - AppSpacing.xxl)
        .clamp(320.0, 820.0)
        .toDouble();
    final dialogHeight = (mediaSize.height - AppSpacing.xxl)
        .clamp(420.0, 760.0)
        .toDouble();

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
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tripDetailsHeaderTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          detailsTrip.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.tripCloseButton,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(AppIcons.clear),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TripDetailsSectionTitle(text: l10n.tripBasicInfo),
                    const SizedBox(height: AppSpacing.sm),
                    TripBasicInfoSection(
                      trip: detailsTrip,
                      financialConfiguration: financialConfiguration,
                      businessLocalTimestamps: businessLocalTimestamps,
                      calculatedTotalExpenses: calculatedTotalExpenses,
                      calculatedNetProfit: calculatedNetProfit,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TripDetailsSectionTitle(text: l10n.tripExpensesTitle),
                    const SizedBox(height: AppSpacing.sm),
                    TripExpensesSection(trip: detailsTrip, state: state),
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

  CurrencyConfiguration? _financialConfiguration(TripsLoaded? state) {
    final company = state?.currentCompanyContext.company;
    if (company == null) return null;

    return CurrencyConfiguration.tryCreate(
      currencyCode: company.baseCurrencyCode,
      fractionDigits: company.baseCurrencyFractionDigits,
    );
  }
}
