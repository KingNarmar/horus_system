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
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      tripId: map['trip_id'] as String,
      oldStatus: map['old_status'] as String?,
      newStatus: map['new_status'] as String? ?? 'created',
      changedByUserId: map['changed_by'] as String?,
      changedByName: map['changed_by_name'] as String?,
      changedByRole: map['changed_by_role'] as String?,
      notes: map['notes'] as String?,
      changedAt: _toDateTime(map['changed_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
