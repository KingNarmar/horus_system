import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/authorized_business_records_db_contract.dart';
import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../domain/entities/route_write_data.dart';
import '../constants/route_db_fields.dart';
import '../mappers/route_mapper.dart';
import '../models/route_model.dart';

abstract class RoutesRemoteDataSource {
  Future<List<RouteModel>> getRoutes({required String companyId});

  Future<RouteModel> getRouteById({
    required String companyId,
    required String id,
  });

  Future<RouteModel> addRoute({
    required RouteWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  });

  Future<RouteModel> saveRoute({
    required String id,
    required RouteWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  });

  Future<RouteModel> deactivateRoute({
    required String companyId,
    required String id,
  });

  Future<RouteModel> reactivateRoute({
    required String companyId,
    required String id,
  });
}

class SupabaseRoutesRemoteDataSource implements RoutesRemoteDataSource {
  final SupabaseClient client;

  const SupabaseRoutesRemoteDataSource(this.client);

  @override
  Future<List<RouteModel>> getRoutes({required String companyId}) async {
    final result = await client.rpc(
      AuthorizedBusinessRecordsDbRpcs.routes,
      params: {AuthorizedBusinessRecordsDbParams.companyId: companyId},
    );
    return _rpcRows(result).map(RouteModel.fromMap).toList();
  }

  @override
  Future<RouteModel> getRouteById({
    required String companyId,
    required String id,
  }) async {
    final result = await client.rpc(
      AuthorizedBusinessRecordsDbRpcs.routes,
      params: {
        AuthorizedBusinessRecordsDbParams.companyId: companyId,
        AuthorizedBusinessRecordsDbParams.routeId: id,
      },
    );
    final records = _rpcRows(result);
    if (records.length != 1) {
      throw const FormatException('Route not found or invalid response.');
    }
    return RouteModel.fromMap(records.single);
  }

  @override
  Future<RouteModel> addRoute({
    required RouteWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  }) async {
    final row = await client
        .from(RouteDbFields.tableName)
        .insert(
          data.toInsertMap(financialConfiguration: financialConfiguration),
        )
        .select(DbCommonFields.id)
        .single();

    return getRouteById(
      companyId: data.companyId,
      id: row[DbCommonFields.id] as String,
    );
  }

  @override
  Future<RouteModel> saveRoute({
    required String id,
    required RouteWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  }) async {
    final row = await client
        .from(RouteDbFields.tableName)
        .update(
          data.toUpdateMap(financialConfiguration: financialConfiguration),
        )
        .eq(DbCommonFields.id, id)
        .eq(DbCommonFields.companyId, data.companyId)
        .select(DbCommonFields.id)
        .single();

    return getRouteById(
      companyId: data.companyId,
      id: row[DbCommonFields.id] as String,
    );
  }

  @override
  Future<RouteModel> deactivateRoute({
    required String companyId,
    required String id,
  }) {
    return _setActiveState(companyId: companyId, id: id, isActive: false);
  }

  @override
  Future<RouteModel> reactivateRoute({
    required String companyId,
    required String id,
  }) {
    return _setActiveState(companyId: companyId, id: id, isActive: true);
  }

  Future<RouteModel> _setActiveState({
    required String companyId,
    required String id,
    required bool isActive,
  }) async {
    final row = await client
        .from(RouteDbFields.tableName)
        .update({
          DbCommonFields.isActive: isActive,
          DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
        })
        .eq(DbCommonFields.id, id)
        .eq(DbCommonFields.companyId, companyId)
        .select(DbCommonFields.id)
        .single();

    return getRouteById(
      companyId: companyId,
      id: row[DbCommonFields.id] as String,
    );
  }

  List<Map<String, dynamic>> _rpcRows(Object? value) {
    if (value is! List) {
      throw const FormatException('Invalid Route read response.');
    }
    return value
        .map((record) {
          if (record is! Map) {
            throw const FormatException('Invalid Route record.');
          }
          return Map<String, dynamic>.from(record);
        })
        .toList(growable: false);
  }
}
