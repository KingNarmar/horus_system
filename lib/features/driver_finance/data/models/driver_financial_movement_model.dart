import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../domain/entities/driver_financial_movement_type.dart';
import '../constants/driver_finance_db_fields.dart';

class DriverFinancialMovementModel {
  final String id;
  final String companyId;
  final String driverId;
  final String? tripId;
  final DriverFinancialMovementType type;
  final double amount;
  final int? amountMinorUnits;
  final String? currencyCode;
  final int? currencyFractionDigits;
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
    this.amountMinorUnits,
    this.currencyCode,
    this.currencyFractionDigits,
    this.tripId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory DriverFinancialMovementModel.fromMap(Map<String, dynamic> map) {
    return DriverFinancialMovementModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      driverId: map[DriverFinanceDbFields.driverId] as String,
      tripId: map[DriverFinanceDbFields.tripId] as String?,
      type: driverFinancialMovementTypeFromValue(
        map[DriverFinanceDbFields.movementType] as String,
      ),
      amount: _toDouble(map[DriverFinanceDbFields.amount]),
      amountMinorUnits: _toIntNullable(
        map[DriverFinanceDbFields.amountMinorUnits],
      ),
      currencyCode: map[DriverFinanceDbFields.currencyCode] as String?,
      currencyFractionDigits: _toIntNullable(
        map[DriverFinanceDbFields.currencyFractionDigits],
      ),
      movementDate: DbDate.decode(
        map[DriverFinanceDbFields.movementDate],
        field: DriverFinanceDbFields.movementDate,
      ),
      notes: map[DriverFinanceDbFields.notes] as String?,
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

  static int? _toIntNullable(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
