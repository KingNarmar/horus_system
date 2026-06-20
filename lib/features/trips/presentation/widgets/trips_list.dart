import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/trip_entity.dart';
import 'trips_cards.dart';
import 'trips_table.dart';

class TripsList extends StatelessWidget {
  final List<TripEntity> trips;
  final bool canManageTrips;
  final bool canUpdateTripStatus;
  final bool canViewTripFinancials;
  final bool Function(String id) isStatusChanging;
  final ValueChanged<TripEntity> onViewDetails;
  final ValueChanged<TripEntity> onEdit;
  final ValueChanged<TripEntity> onUpdateStatus;

  const TripsList({
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
        if (constraints.maxWidth >= AppSizes.desktopMinWidth) {
          return TripsTable(
            trips: trips,
            canManageTrips: canManageTrips,
            canUpdateTripStatus: canUpdateTripStatus,
            canViewTripFinancials: canViewTripFinancials,
            isStatusChanging: isStatusChanging,
            onViewDetails: onViewDetails,
            onEdit: onEdit,
            onUpdateStatus: onUpdateStatus,
          );
        }

        return TripsCards(
          trips: trips,
          canManageTrips: canManageTrips,
          canUpdateTripStatus: canUpdateTripStatus,
          canViewTripFinancials: canViewTripFinancials,
          isStatusChanging: isStatusChanging,
          onViewDetails: onViewDetails,
          onEdit: onEdit,
          onUpdateStatus: onUpdateStatus,
        );
      },
    );
  }
}
