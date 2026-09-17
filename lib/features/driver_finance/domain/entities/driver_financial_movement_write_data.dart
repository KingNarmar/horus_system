import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';
import 'driver_financial_movement_type.dart';

class DriverFinancialMovementWriteData {
  final String companyId;
  final String driverId;
  final String? tripId;
  final DriverFinancialMovementType type;
  final Money amount;
  final int currencyFractionDigits;
  final BusinessDate movementDate;
  final String? notes;

  const DriverFinancialMovementWriteData({
    required this.companyId,
    required this.driverId,
    required this.type,
    required this.amount,
    required this.currencyFractionDigits,
    required this.movementDate,
    this.tripId,
    this.notes,
  });
}
