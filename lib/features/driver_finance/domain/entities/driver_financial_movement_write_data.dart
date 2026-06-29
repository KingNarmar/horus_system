import 'driver_financial_movement_type.dart';

class DriverFinancialMovementWriteData {
  final String companyId;
  final String driverId;
  final String? tripId;
  final DriverFinancialMovementType type;
  final double amount;
  final DateTime movementDate;
  final String? notes;

  const DriverFinancialMovementWriteData({
    required this.companyId,
    required this.driverId,
    required this.type,
    required this.amount,
    required this.movementDate,
    this.tripId,
    this.notes,
  });
}
