import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';
import 'driver_financial_movement_type.dart';

class DriverFinancialMovement {
  final String id;
  final String companyId;
  final String driverId;
  final String? tripId;
  final DriverFinancialMovementType movementType;
  final Money amount;
  final int currencyFractionDigits;
  final BusinessDate movementDate;
  final String? notes;
  final DateTime? createdAt;

  const DriverFinancialMovement({
    required this.id,
    required this.companyId,
    required this.driverId,
    required this.movementType,
    required this.amount,
    required this.currencyFractionDigits,
    required this.movementDate,
    this.tripId,
    this.notes,
    this.createdAt,
  });
}
