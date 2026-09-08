import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../domain/entities/driver_financial_movement_type.dart';

class DriverFinancialMovementModel {
  final String id;
  final String companyId;
  final String driverId;
  final String? tripId;
  final DriverFinancialMovementType type;
  final double amount;
  final BusinessDate movementDate;
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
      type: driverFinancialMovementTypeFromValue(
        map['movement_type'] as String,
      ),
      amount: _toDouble(map['amount']),
      movementDate: DbDate.decode(map['movement_date'], field: 'movement_date'),
      notes: map['notes'] as String?,
      createdAt: DbTimestamp.decodeNullable(
        map['created_at'],
        field: 'created_at',
      ),
      updatedAt: DbTimestamp.decodeNullable(
        map['updated_at'],
        field: 'updated_at',
      ),
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
