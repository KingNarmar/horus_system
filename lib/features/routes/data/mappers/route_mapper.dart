import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/services/money_decimal_codec.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/route_write_data.dart';
import '../constants/route_db_fields.dart';
import '../models/route_model.dart';

const _defaultFreightRatePerTonAuditKey = 'default_freight_rate_per_ton';
const _moneyCodec = MoneyDecimalCodec();

extension RouteModelMapper on RouteModel {
  RouteEntity toEntity({
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return RouteEntity(
      id: id,
      companyId: companyId,
      loadingLocation: loadingLocation,
      unloadingLocation: unloadingLocation,
      governorateFrom: governorateFrom,
      governorateTo: governorateTo,
      defaultFreightRatePerTon: _decodeOptionalMoney(
        defaultFreightRatePerTonDecimal,
        financialConfiguration: financialConfiguration,
      ),
      notes: notes,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toAuditValues() {
    return {
      DbCommonFields.id: id,
      DbCommonFields.companyId: companyId,
      RouteDbFields.loadingLocation: loadingLocation,
      RouteDbFields.unloadingLocation: unloadingLocation,
      RouteDbFields.governorateFrom: governorateFrom,
      RouteDbFields.governorateTo: governorateTo,
      _defaultFreightRatePerTonAuditKey: defaultFreightRatePerTonDecimal,
      RouteDbFields.notes: notes,
      DbCommonFields.isActive: isActive,
      DbCommonFields.createdAt: createdAt?.toUtc().toIso8601String(),
      DbCommonFields.updatedAt: updatedAt?.toUtc().toIso8601String(),
    };
  }
}

extension RouteWriteDataMapper on RouteWriteData {
  Map<String, dynamic> toInsertMap({
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return {
      DbCommonFields.companyId: companyId,
      RouteDbFields.loadingLocation: loadingLocation,
      RouteDbFields.unloadingLocation: unloadingLocation,
      RouteDbFields.governorateFrom: governorateFrom,
      RouteDbFields.governorateTo: governorateTo,
      RouteDbFields.defaultFreightRatePerTon: _encodeOptionalMoney(
        defaultFreightRatePerTon,
        financialConfiguration: financialConfiguration,
      ),
      RouteDbFields.notes: notes,
    };
  }

  Map<String, dynamic> toUpdateMap({
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return {
      RouteDbFields.loadingLocation: loadingLocation,
      RouteDbFields.unloadingLocation: unloadingLocation,
      RouteDbFields.governorateFrom: governorateFrom,
      RouteDbFields.governorateTo: governorateTo,
      RouteDbFields.defaultFreightRatePerTon: _encodeOptionalMoney(
        defaultFreightRatePerTon,
        financialConfiguration: financialConfiguration,
      ),
      RouteDbFields.notes: notes,
      DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    };
  }
}

Money? _decodeOptionalMoney(
  String? decimal, {
  required CurrencyConfiguration? financialConfiguration,
}) {
  if (decimal == null) return null;
  final configuration = financialConfiguration;
  if (configuration == null) {
    throw StateError(
      'Financial configuration is required to decode Route freight rate.',
    );
  }

  final money = _moneyCodec.tryDecodeNonNegative(
    decimal,
    configuration: configuration,
  );
  if (money == null) {
    throw FormatException('Invalid Route freight rate decimal.', decimal);
  }
  return money;
}

String? _encodeOptionalMoney(
  Money? money, {
  required CurrencyConfiguration? financialConfiguration,
}) {
  if (money == null) return null;
  final configuration = financialConfiguration;
  if (configuration == null) {
    throw StateError(
      'Financial configuration is required to encode Route freight rate.',
    );
  }

  return _moneyCodec.encodeNonNegative(money, configuration: configuration);
}
