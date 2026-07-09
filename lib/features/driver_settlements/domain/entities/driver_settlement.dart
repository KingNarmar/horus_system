import 'driver_settlement_calculation_result.dart';
import 'driver_settlement_item.dart';
import 'driver_settlement_period.dart';
import 'driver_settlement_status.dart';

class DriverSettlement {
  final String id;
  final String companyId;
  final String driverId;
  final DriverSettlementPeriod period;
  final DriverSettlementCalculationResult calculation;
  final DriverSettlementStatus status;
  final String? notes;
  final DateTime? finalizedAt;
  final String? finalizedBy;
  final DateTime? voidedAt;
  final String? voidedBy;
  final String? voidReason;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<DriverSettlementItem> items;

  const DriverSettlement({
    required this.id,
    required this.companyId,
    required this.driverId,
    required this.period,
    required this.calculation,
    required this.status,
    this.notes,
    this.finalizedAt,
    this.finalizedBy,
    this.voidedAt,
    this.voidedBy,
    this.voidReason,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });
}
