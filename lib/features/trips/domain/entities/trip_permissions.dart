class TripPermissions {
  final bool canManageTrips;
  final bool canUpdateTripStatus;
  final bool canManageTripDocuments;
  final bool canViewTripFinancials;

  const TripPermissions({
    required this.canManageTrips,
    required this.canUpdateTripStatus,
    required this.canManageTripDocuments,
    required this.canViewTripFinancials,
  });
}
