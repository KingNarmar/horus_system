import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/driver_write_data.dart';
import '../mappers/driver_mapper.dart';
import '../models/driver_model.dart';
import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../constants/driver_db_fields.dart';

abstract class DriversRemoteDataSource {
  Future<List<DriverModel>> getDrivers({required String companyId});

  Future<DriverModel> getDriverById({
    required String companyId,
    required String driverId,
  });

  Future<DriverModel> addDriver({required DriverWriteData data});

  Future<DriverModel> updateDriver({
    required String driverId,
    required DriverWriteData data,
  });

  Future<DriverModel> deactivateDriver({
    required String companyId,
    required String driverId,
  });

  Future<DriverModel> reactivateDriver({
    required String companyId,
    required String driverId,
  });
}

class SupabaseDriversRemoteDataSource implements DriversRemoteDataSource {
  static const String columns = DriverDbFields.allColumns;

  final SupabaseClient client;

  const SupabaseDriversRemoteDataSource(this.client);

  @override
  Future<List<DriverModel>> getDrivers({required String companyId}) async {
    final response = await client
        .from(DriverDbFields.tableName)
        .select(columns)
        .eq(DbCommonFields.companyId, companyId)
        .order(DriverDbFields.fullName);

    return response
        .map((item) => DriverModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<DriverModel> getDriverById({
    required String companyId,
    required String driverId,
  }) async {
    final response = await client
        .from(DriverDbFields.tableName)
        .select(columns)
        .eq(DbCommonFields.id, driverId)
        .eq(DbCommonFields.companyId, companyId)
        .single();

    return DriverModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<DriverModel> addDriver({required DriverWriteData data}) async {
    final response = await client
        .from(DriverDbFields.tableName)
        .insert(data.toInsertMap())
        .select(columns)
        .single();

    return DriverModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<DriverModel> updateDriver({
    required String driverId,
    required DriverWriteData data,
  }) async {
    final response = await client
        .from(DriverDbFields.tableName)
        .update(data.toUpdateMap())
        .eq(DbCommonFields.id, driverId)
        .eq(DbCommonFields.companyId, data.companyId)
        .select(columns)
        .single();

    return DriverModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<DriverModel> deactivateDriver({
    required String companyId,
    required String driverId,
  }) async {
    final response = await client
        .from(DriverDbFields.tableName)
        .update({
          DbCommonFields.isActive: false,
          DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
        })
        .eq(DbCommonFields.id, driverId)
        .eq(DbCommonFields.companyId, companyId)
        .select(columns)
        .single();

    return DriverModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<DriverModel> reactivateDriver({
    required String companyId,
    required String driverId,
  }) async {
    final response = await client
        .from(DriverDbFields.tableName)
        .update({
          DbCommonFields.isActive: true,
          DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
        })
        .eq(DbCommonFields.id, driverId)
        .eq(DbCommonFields.companyId, companyId)
        .select(columns)
        .single();

    return DriverModel.fromMap(Map<String, dynamic>.from(response));
  }
}
