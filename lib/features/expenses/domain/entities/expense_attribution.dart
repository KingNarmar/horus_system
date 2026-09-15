final class ExpenseAttribution {
  final String? tripId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;

  const ExpenseAttribution({
    this.tripId,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
  });

  bool get isGeneral =>
      tripId == null &&
      driverId == null &&
      tractorHeadId == null &&
      trailerId == null;

  bool get isTripAttributed => tripId != null;

  bool get hasStandaloneAttribution =>
      tripId == null &&
      (driverId != null || tractorHeadId != null || trailerId != null);
}
