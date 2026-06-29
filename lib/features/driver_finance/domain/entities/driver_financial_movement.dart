import 'driver_financial_movement_type.dart';

class DriverFinancialMovement {
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

  const DriverFinancialMovement({
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
}
