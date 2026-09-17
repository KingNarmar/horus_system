import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_type.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/services/money_decimal_codec.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../domain/entities/driver_financial_movement.dart';
import '../../domain/entities/driver_financial_movement_write_data.dart';
import '../constants/driver_finance_db_fields.dart';
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
      DriverFinanceDbFields.driverId: driverId,
      DriverFinanceDbFields.tripId: tripId,
      DriverFinanceDbFields.movementType: type.value,
      DriverFinanceDbFields.amount: amount,
      DriverFinanceDbFields.amountMinorUnits: amountMinorUnits,
      DriverFinanceDbFields.currencyCode: currencyCode,
      DriverFinanceDbFields.currencyFractionDigits: currencyFractionDigits,
      DriverFinanceDbFields.movementDate: DbDate.encode(movementDate),
      DriverFinanceDbFields.notes: notes,
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
      ..._mutableValues(),
    };
  }

  Map<String, dynamic> toUpdateMap() => _mutableValues();

  Map<String, dynamic> _mutableValues() {
    final configuration = CurrencyConfiguration(
      currency: amount.currency,
      fractionDigits: currencyFractionDigits,
    );
    final decimalAmount = const MoneyDecimalCodec().encodeNonNegative(
      amount,
      configuration: configuration,
    );

    return {
      DriverFinanceDbFields.driverId: driverId,
      DriverFinanceDbFields.tripId: tripId,
      DriverFinanceDbFields.movementType: type.value,
      DriverFinanceDbFields.amount: decimalAmount,
      DriverFinanceDbFields.amountMinorUnits: amount.minorUnits,
      DriverFinanceDbFields.currencyCode: amount.currency.value,
      DriverFinanceDbFields.currencyFractionDigits: currencyFractionDigits,
      DriverFinanceDbFields.movementDate: DbDate.encode(movementDate),
      DriverFinanceDbFields.notes: notes,
    };
  }
}
