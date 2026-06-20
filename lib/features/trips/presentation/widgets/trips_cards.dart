import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/trip_entity.dart';
import 'trip_card.dart';

class TripsCards extends StatelessWidget {
  final List<TripEntity> trips;
  final bool canManageTrips;
  final bool canUpdateTripStatus;
  final bool canViewTripFinancials;
  final bool Function(String id) isStatusChanging;
  final ValueChanged<TripEntity> onViewDetails;
  final ValueChanged<TripEntity> onEdit;
  final ValueChanged<TripEntity> onUpdateStatus;

  const TripsCards({
    required this.trips,
    required this.canManageTrips,
    required this.canUpdateTripStatus,
    required this.canViewTripFinancials,
    required this.isStatusChanging,
    required this.onViewDetails,
    required this.onEdit,
    required this.onUpdateStatus,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= AppSizes.tabletMaxContentWidth;
        final cardWidth = useTwoColumns
            ? (constraints.maxWidth - AppSpacing.md) / 2
            : constraints.maxWidth;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final trip in trips)
                SizedBox(
                  width: cardWidth,
                  child: TripCard(
                    trip: trip,
                    canManageTrips: canManageTrips,
                    canUpdateTripStatus: canUpdateTripStatus,
                    canViewTripFinancials: canViewTripFinancials,
                    isChanging: isStatusChanging(trip.id),
                    onViewDetails: onViewDetails,
                    onEdit: onEdit,
                    onUpdateStatus: onUpdateStatus,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
