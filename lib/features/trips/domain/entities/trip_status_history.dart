import 'trip_status.dart';

class TripStatusHistory {
  final String id;
  final String companyId;
  final String tripId;
  final TripStatus? oldStatus;
  final TripStatus newStatus;
  final String? changedByUserId;
  final String? changedByName;
  final String? changedByRole;
  final String? notes;
  final DateTime changedAt;

  const TripStatusHistory({
    required this.id,
    required this.companyId,
    required this.tripId,
    required this.newStatus,
    required this.changedAt,
    this.oldStatus,
    this.changedByUserId,
    this.changedByName,
    this.changedByRole,
    this.notes,
  });

  bool get hasStatusChanged {
    return oldStatus == null || oldStatus != newStatus;
  }
}
