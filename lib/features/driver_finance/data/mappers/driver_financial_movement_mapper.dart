import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_type.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/driver_financial_movement.dart';
import '../../domain/entities/driver_financial_movement_write_data.dart';
import '../models/driver_financial_movement_model.dart';

extension DriverFinancialMovementModelMapper on DriverFinancialMovementModel {
  DriverFinancialMovement toEntity() {
    return DriverFinancialMovement(
      id: id,
      companyId: companyId,
      driverId: driverId,
      tripId: tripId,
      type: type,
      amount: amount,
      movementDate: movementDate,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toAuditValues() {
    return {
      DbCommonFields.id: id,
      DbCommonFields.companyId: companyId,
      'driver_id': driverId,
      'trip_id': tripId,
      'movement_type': type.value,
      'amount': amount,
      'movement_date': _dateOnly(movementDate),
      'notes': notes,
      DbCommonFields.createdAt: createdAt?.toUtc().toIso8601String(),
      DbCommonFields.updatedAt: updatedAt?.toUtc().toIso8601String(),
    };
  }
}

extension DriverFinancialMovementWriteDataMapper
    on DriverFinancialMovementWriteData {
  Map<String, dynamic> toInsertMap() {
    return {
      DbCommonFields.companyId: companyId,
      'driver_id': driverId,
      'trip_id': tripId,
      'movement_type': type.value,
      'amount': amount,
      'movement_date': _dateOnly(movementDate),
      'notes': notes,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'trip_id': tripId,
      'movement_type': type.value,
      'amount': amount,
      'movement_date': _dateOnly(movementDate),
      'notes': notes,
      DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    };
  }
}

String _dateOnly(DateTime value) {
  final utc = value.toUtc();
  return '${utc.year.toString().padLeft(4, '0')}-'
      '${utc.month.toString().padLeft(2, '0')}-'
      '${utc.day.toString().padLeft(2, '0')}';
}
