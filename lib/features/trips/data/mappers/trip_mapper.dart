import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/services/money_decimal_codec.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_form_lookups.dart';
import '../../domain/entities/trip_lookup_option.dart';
import '../../domain/entities/trip_route_lookup_option.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_status_history.dart';
import '../../domain/entities/trip_write_data.dart';
import '../../domain/value_objects/quantity_tons.dart';
import '../constants/trip_db_fields.dart';
import '../models/trip_lookup_models.dart';
import '../models/trip_model.dart';
import '../models/trip_status_history_model.dart';

const _commercialAmountAuditKey = 'commercial_amount';
const _moneyCodec = MoneyDecimalCodec();

extension TripModelMapper on TripModel {
  TripEntity toEntity({
    required CurrencyConfiguration? financialConfiguration,
  }) {
    final quantity = _decodeQuantity(quantityTonsDecimal);
    final rate = _decodeMoney(
      agreedFreightRatePerTonDecimal,
      financialConfiguration: financialConfiguration,
      fieldName: TripDbFields.agreedFreightRatePerTon,
    );
    final commercialAmount = _decodeCommercialAmount(
      commercialAmountDecimal,
      agreedRate: rate,
      financialConfiguration: financialConfiguration,
    );

    return TripEntity(
      id: id,
      companyId: companyId,
      customerId: customerId,
      routeId: routeId,
      driverId: driverId,
      tractorHeadId: tractorHeadId,
      trailerId: trailerId,
      status: TripStatusX.fromValue(status),
      loadingOrderNumber: loadingOrderNumber,
      waybillNumber: waybillNumber,
      quantityTons: quantity,
      agreedFreightRatePerTon: rate,
      commercialAmount: commercialAmount,
      totalExpenses: totalExpenses,
      scheduledLoadingAt: scheduledLoadingAt,
      scheduledDeliveryAt: scheduledDeliveryAt,
      actualLoadingAt: actualLoadingAt,
      actualDeliveryAt: actualDeliveryAt,
      notes: notes,
      customerName: customerName,
      routeName: routeName,
      driverName: driverName,
      tractorHeadPlateNumber: tractorHeadPlateNumber,
      trailerPlateNumber: trailerPlateNumber,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toAuditValues() {
    return {
      DbCommonFields.id: id,
      DbCommonFields.companyId: companyId,
      TripDbFields.customerId: customerId,
      TripDbFields.routeId: routeId,
      TripDbFields.driverId: driverId,
      TripDbFields.tractorHeadId: tractorHeadId,
      TripDbFields.trailerId: trailerId,
      TripDbFields.status: status,
      TripDbFields.loadingOrderNumber: loadingOrderNumber,
      TripDbFields.waybillNumber: waybillNumber,
      TripDbFields.quantityTons: quantityTonsDecimal,
      TripDbFields.agreedFreightRatePerTon: agreedFreightRatePerTonDecimal,
      _commercialAmountAuditKey: commercialAmountDecimal,
      TripDbFields.totalExpenses: totalExpenses,
      TripDbFields.scheduledLoadingAt: scheduledLoadingAt
          ?.toUtc()
          .toIso8601String(),
      TripDbFields.scheduledDeliveryAt: scheduledDeliveryAt
          ?.toUtc()
          .toIso8601String(),
      TripDbFields.actualLoadingAt: actualLoadingAt?.toUtc().toIso8601String(),
      TripDbFields.actualDeliveryAt: actualDeliveryAt
          ?.toUtc()
          .toIso8601String(),
      TripDbFields.notes: notes,
      TripDbFields.customerNameAlias: customerName,
      TripDbFields.routeNameAlias: routeName,
      TripDbFields.driverNameAlias: driverName,
      TripDbFields.tractorHeadPlateNumberAlias: tractorHeadPlateNumber,
      TripDbFields.trailerPlateNumberAlias: trailerPlateNumber,
      DbCommonFields.createdAt: createdAt?.toUtc().toIso8601String(),
      DbCommonFields.updatedAt: updatedAt?.toUtc().toIso8601String(),
    };
  }
}

extension TripFormLookupsModelMapper on TripFormLookupsModel {
  TripFormLookups toEntity({
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return TripFormLookups(
      customers: customers
          .map((model) => TripLookupOption(id: model.id, label: model.label))
          .toList(),
      routes: routes
          .map(
            (model) => TripRouteLookupOption(
              id: model.id,
              label: model.label,
              defaultFreightRatePerTon: _decodeMoney(
                model.defaultFreightRatePerTonDecimal,
                financialConfiguration: financialConfiguration,
                fieldName: TripLookupDbFields.defaultFreightRatePerTon,
              ),
            ),
          )
          .toList(),
      drivers: drivers
          .map((model) => TripLookupOption(id: model.id, label: model.label))
          .toList(),
      tractorHeads: tractorHeads
          .map((model) => TripLookupOption(id: model.id, label: model.label))
          .toList(),
      trailers: trailers
          .map((model) => TripLookupOption(id: model.id, label: model.label))
          .toList(),
    );
  }
}

extension TripStatusHistoryModelMapper on TripStatusHistoryModel {
  TripStatusHistory toEntity() {
    return TripStatusHistory(
      id: id,
      companyId: companyId,
      tripId: tripId,
      oldStatus: oldStatus == null ? null : TripStatusX.fromValue(oldStatus),
      newStatus: TripStatusX.fromValue(newStatus),
      changedByUserId: changedByUserId,
      changedByName: changedByName,
      changedByRole: changedByRole,
      notes: notes,
      changedAt: changedAt,
    );
  }
}

extension TripWriteDataMapper on TripWriteData {
  Map<String, dynamic> toInsertMap({
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return {
      DbCommonFields.companyId: companyId,
      TripDbFields.customerId: customerId,
      TripDbFields.routeId: routeId,
      TripDbFields.driverId: driverId,
      TripDbFields.tractorHeadId: tractorHeadId,
      TripDbFields.trailerId: trailerId,
      TripDbFields.loadingOrderNumber: loadingOrderNumber,
      TripDbFields.waybillNumber: waybillNumber,
      TripDbFields.quantityTons: quantityTons?.toDecimalString(),
      TripDbFields.agreedFreightRatePerTon: _encodeMoney(
        agreedFreightRatePerTon,
        financialConfiguration: financialConfiguration,
      ),
      TripDbFields.commercialAmount: _encodeMoney(
        commercialAmount,
        financialConfiguration: financialConfiguration,
      ),
      TripDbFields.scheduledLoadingAt: _toUtcIsoString(scheduledLoadingAt),
      TripDbFields.scheduledDeliveryAt: _toUtcIsoString(scheduledDeliveryAt),
      TripDbFields.actualLoadingAt: _toUtcIsoString(actualLoadingAt),
      TripDbFields.actualDeliveryAt: _toUtcIsoString(actualDeliveryAt),
      TripDbFields.notes: notes,
    };
  }

  Map<String, dynamic> toUpdateMap({
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return {
      TripDbFields.customerId: customerId,
      TripDbFields.routeId: routeId,
      TripDbFields.driverId: driverId,
      TripDbFields.tractorHeadId: tractorHeadId,
      TripDbFields.trailerId: trailerId,
      TripDbFields.loadingOrderNumber: loadingOrderNumber,
      TripDbFields.waybillNumber: waybillNumber,
      TripDbFields.quantityTons: quantityTons?.toDecimalString(),
      TripDbFields.agreedFreightRatePerTon: _encodeMoney(
        agreedFreightRatePerTon,
        financialConfiguration: financialConfiguration,
      ),
      TripDbFields.commercialAmount: _encodeMoney(
        commercialAmount,
        financialConfiguration: financialConfiguration,
      ),
      TripDbFields.scheduledLoadingAt: _toUtcIsoString(scheduledLoadingAt),
      TripDbFields.scheduledDeliveryAt: _toUtcIsoString(scheduledDeliveryAt),
      TripDbFields.actualLoadingAt: _toUtcIsoString(actualLoadingAt),
      TripDbFields.actualDeliveryAt: _toUtcIsoString(actualDeliveryAt),
      TripDbFields.notes: notes,
      DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    };
  }
}

extension TripStatusMapper on TripStatus {
  Map<String, dynamic> toTripStatusUpdateMap() {
    return {
      TripDbFields.status: value,
      DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    };
  }

  Map<String, dynamic> toHistoryInsertMap({
    required String companyId,
    required String tripId,
    required TripStatus? oldStatus,
    required String actorRole,
    String? notes,
  }) {
    return {
      DbCommonFields.companyId: companyId,
      TripStatusHistoryDbFields.tripId: tripId,
      TripStatusHistoryDbFields.oldStatus: oldStatus?.value,
      TripStatusHistoryDbFields.newStatus: value,
      TripStatusHistoryDbFields.changedByRole: actorRole,
      TripStatusHistoryDbFields.notes: notes,
    };
  }
}

QuantityTons? _decodeQuantity(String? decimal) {
  if (decimal == null) return null;
  final quantity = QuantityTons.tryParse(decimal);
  if (quantity == null) {
    throw FormatException('Invalid Trip quantity decimal.', decimal);
  }
  return quantity;
}

Money? _decodeCommercialAmount(
  String? decimal, {
  required Money? agreedRate,
  required CurrencyConfiguration? financialConfiguration,
}) {
  if (decimal == null) return null;
  if (agreedRate == null && _isZeroDecimal(decimal)) return null;
  return _decodeMoney(
    decimal,
    financialConfiguration: financialConfiguration,
    fieldName: TripDbFields.commercialAmount,
  );
}

Money? _decodeMoney(
  String? decimal, {
  required CurrencyConfiguration? financialConfiguration,
  required String fieldName,
}) {
  if (decimal == null) return null;
  final configuration = financialConfiguration;
  if (configuration == null) {
    throw StateError('Financial configuration is required to decode $fieldName.');
  }

  final money = _moneyCodec.tryDecodeNonNegative(
    decimal,
    configuration: configuration,
  );
  if (money == null) {
    throw FormatException('Invalid monetary decimal for $fieldName.', decimal);
  }
  return money;
}

String? _encodeMoney(
  Money? money, {
  required CurrencyConfiguration? financialConfiguration,
}) {
  if (money == null) return null;
  final configuration = financialConfiguration;
  if (configuration == null) {
    throw StateError('Financial configuration is required to encode Trip money.');
  }
  return _moneyCodec.encodeNonNegative(
    money,
    configuration: configuration,
  );
}

bool _isZeroDecimal(String value) {
  return RegExp(r'^0+(?:\.0+)?$').hasMatch(value.trim());
}

String? _toUtcIsoString(DateTime? value) {
  return value?.toUtc().toIso8601String();
}
