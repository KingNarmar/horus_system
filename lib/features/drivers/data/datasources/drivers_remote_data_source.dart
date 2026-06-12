import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/driver_write_data.dart';
import '../mappers/driver_mapper.dart';
import '../models/driver_model.dart';

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
  static const String columns =
      'id,company_id,full_name,phone,national_id,license_number,license_expiry_date,notes,is_active,created_at,updated_at';

  final SupabaseClient client;

  const SupabaseDriversRemoteDataSource(this.client);

  @override
  Future<List<DriverModel>> getDrivers({required String companyId}) async {
    final response = await client
        .from('drivers')
        .select(columns)
        .eq('company_id', companyId)
        .order('full_name');

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
        .from('drivers')
        .select(columns)
        .eq('id', driverId)
        .eq('company_id', companyId)
        .single();

    return DriverModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<DriverModel> addDriver({required DriverWriteData data}) async {
    final response = await client
        .from('drivers')
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
        .from('drivers')
        .update(data.toUpdateMap())
        .eq('id', driverId)
        .eq('company_id', data.companyId)
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
        .from('drivers')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', driverId)
        .eq('company_id', companyId)
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
        .from('drivers')
        .update({
          'is_active': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', driverId)
        .eq('company_id', companyId)
        .select(columns)
        .single();

    return DriverModel.fromMap(Map<String, dynamic>.from(response));
  }
}
