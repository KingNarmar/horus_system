import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/route_write_data.dart';
import '../mappers/route_mapper.dart';
import '../models/route_model.dart';

const _routesTable = 'routes';

const _routeColumns =
    'id, company_id, loading_location, unloading_location, governorate_from, governorate_to, default_freight_price, notes, is_active, created_at, updated_at';

abstract class RoutesRemoteDataSource {
  Future<List<RouteModel>> getRoutes({required String companyId});

  Future<RouteModel> getRouteById({
    required String companyId,
    required String id,
  });

  Future<RouteModel> addRoute({required RouteWriteData data});

  Future<RouteModel> saveRoute({
    required String id,
    required RouteWriteData data,
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
    final rows = await client
        .from(_routesTable)
        .select(_routeColumns)
        .eq(DbCommonFields.companyId, companyId)
        .order('loading_location');

    return rows
        .map((row) => RouteModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<RouteModel> getRouteById({
    required String companyId,
    required String id,
  }) async {
    final row = await client
        .from(_routesTable)
        .select(_routeColumns)
        .eq(DbCommonFields.id, id)
        .eq(DbCommonFields.companyId, companyId)
        .single();

    return RouteModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<RouteModel> addRoute({required RouteWriteData data}) async {
    final row = await client
        .from(_routesTable)
        .insert(data.toInsertMap())
        .select(_routeColumns)
        .single();

    return RouteModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<RouteModel> saveRoute({
    required String id,
    required RouteWriteData data,
  }) async {
    final row = await client
        .from(_routesTable)
        .update(data.toUpdateMap())
        .eq(DbCommonFields.id, id)
        .eq(DbCommonFields.companyId, data.companyId)
        .select(_routeColumns)
        .single();

    return RouteModel.fromMap(Map<String, dynamic>.from(row));
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
        .from(_routesTable)
        .update({
          DbCommonFields.isActive: isActive,
          DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
        })
        .eq(DbCommonFields.id, id)
        .eq(DbCommonFields.companyId, companyId)
        .select(_routeColumns)
        .single();

    return RouteModel.fromMap(Map<String, dynamic>.from(row));
  }
}
