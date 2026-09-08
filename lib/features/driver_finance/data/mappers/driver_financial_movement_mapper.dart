import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_type.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_date.dart';
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
      'movement_date': DbDate.encode(movementDate),
      'notes': notes,
      DbCommonFields.createdAt: DbTimestamp.encodeNullable(createdAt),
      DbCommonFields.updatedAt: DbTimestamp.encodeNullable(updatedAt),
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
      'movement_date': DbDate.encode(movementDate),
      'notes': notes,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'trip_id': tripId,
      'movement_type': type.value,
      'amount': amount,
      'movement_date': DbDate.encode(movementDate),
      'notes': notes,
    };
  }
}
