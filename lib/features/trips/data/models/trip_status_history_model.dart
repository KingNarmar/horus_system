import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/trip_db_fields.dart';

class TripStatusHistoryModel {
  final String id;
  final String companyId;
  final String tripId;
  final String? oldStatus;
  final String newStatus;
  final String? changedByUserId;
  final String? changedByName;
  final String? changedByRole;
  final String? notes;
  final DateTime changedAt;

  const TripStatusHistoryModel({
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

  factory TripStatusHistoryModel.fromMap(Map<String, dynamic> map) {
    return TripStatusHistoryModel(
      id: map[DbCommonFields.id] as String,
      companyId: map[DbCommonFields.companyId] as String,
      tripId: map[TripStatusHistoryDbFields.tripId] as String,
      oldStatus: map[TripStatusHistoryDbFields.oldStatus] as String?,
      newStatus: map[TripStatusHistoryDbFields.newStatus] as String? ?? 'created',
      changedByUserId: map[TripStatusHistoryDbFields.changedBy] as String?,
      changedByName: map[TripStatusHistoryDbFields.changedByName] as String?,
      changedByRole: map[TripStatusHistoryDbFields.changedByRole] as String?,
      notes: map[TripStatusHistoryDbFields.notes] as String?,
      changedAt:
          _toDateTime(map[TripStatusHistoryDbFields.changedAt]) ?? DateTime.now(),
    );
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
