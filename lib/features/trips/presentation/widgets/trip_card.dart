import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../helpers/trip_formatters.dart';
import 'trip_actions.dart';
import 'trip_info_text.dart';
import 'trip_status_chip.dart';

class TripCard extends StatelessWidget {
  final TripEntity trip;
  final bool canManageTrips;
  final bool canUpdateTripStatus;
  final bool canViewTripFinancials;
  final bool isChanging;
  final ValueChanged<TripEntity> onViewDetails;
  final ValueChanged<TripEntity> onEdit;
  final ValueChanged<TripEntity> onUpdateStatus;

  const TripCard({
    required this.trip,
    required this.canManageTrips,
    required this.canUpdateTripStatus,
    required this.canViewTripFinancials,
    required this.isChanging,
    required this.onViewDetails,
    required this.onEdit,
    required this.onUpdateStatus,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notes = trip.notes?.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TripCardHeader(trip: trip),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.md,
              children: [
                TripInfoText(
                  label: l10n.tripCustomerHeader,
                  value: TripFormatters.optionalText(
                    trip.customerName,
                    l10n.tripEmptyValue,
                  ),
                ),
                TripInfoText(
                  label: l10n.tripRouteHeader,
                  value: TripFormatters.optionalText(
                    trip.routeName,
                    l10n.tripEmptyValue,
                  ),
                ),
                TripInfoText(
                  label: l10n.tripDriverHeader,
                  value: TripFormatters.optionalText(
                    trip.driverName,
                    l10n.tripEmptyValue,
                  ),
                ),
                TripInfoText(
                  label: l10n.tripVehicleHeader,
                  value: TripFormatters.vehicleText(trip, l10n.tripEmptyValue),
                ),
                TripInfoText(
                  label: l10n.tripQuantityHeader,
                  value: TripFormatters.quantityTons(
                    trip.quantityTons,
                    l10n.tripEmptyValue,
                    l10n.tripTonsSuffix,
                  ),
                ),
                if (canViewTripFinancials)
                  TripInfoText(
                    label: l10n.tripFreightPriceHeader,
                    value: TripFormatters.money(
                      trip.freightPrice,
                      l10n.tripEmptyValue,
                    ),
                  ),
              ],
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(notes),
            ],
            const SizedBox(height: AppSpacing.lg),
            TripActions(
              trip: trip,
              canManageTrips: canManageTrips,
              canUpdateTripStatus: canUpdateTripStatus,
              isChanging: isChanging,
              onViewDetails: onViewDetails,
              onEdit: onEdit,
              onUpdateStatus: onUpdateStatus,
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCardHeader extends StatelessWidget {
  final TripEntity trip;

  const _TripCardHeader({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          trip.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        TripStatusChip(trip: trip),
      ],
    );
  }
}
