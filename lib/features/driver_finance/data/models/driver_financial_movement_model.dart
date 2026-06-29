import '../../domain/entities/driver_financial_movement_type.dart';

class DriverFinancialMovementModel {
  final String id;
  final String companyId;
  final String driverId;
  final String? tripId;
  final DriverFinancialMovementType type;
  final double amount;
  final DateTime movementDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DriverFinancialMovementModel({
    required this.id,
    required this.companyId,
    required this.driverId,
    required this.type,
    required this.amount,
    required this.movementDate,
    this.tripId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory DriverFinancialMovementModel.fromMap(Map<String, dynamic> map) {
    return DriverFinancialMovementModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      driverId: map['driver_id'] as String,
      tripId: map['trip_id'] as String?,
      type: driverFinancialMovementTypeFromValue(map['movement_type'] as String),
      amount: _toDouble(map['amount']),
      movementDate: _toDateTime(map['movement_date']) ?? DateTime.now(),
      notes: map['notes'] as String?,
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
