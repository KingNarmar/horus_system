import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/tractor_head_write_data.dart';
import '../../domain/entities/trailer_write_data.dart';
import '../constants/tractor_head_db_fields.dart';
import '../constants/trailer_db_fields.dart';
import '../mappers/tractor_mapper.dart';
import '../mappers/trailers_mapper.dart';
import '../models/tractor_head_model.dart';
import '../models/trailer_model.dart';

abstract class FleetRemoteDataSource {
  Future<List<TractorHeadModel>> getTractorHeads({required String companyId});

  Future<List<TrailerModel>> getTrailers({required String companyId});

  Future<TractorHeadModel> getTractorHeadById({required String companyId, required String id});

  Future<TrailerModel> getTrailerById({required String companyId, required String id});

  Future<TractorHeadModel> addTractorHead({required TractorHeadWriteData data});

  Future<TractorHeadModel> saveTractorHead({required String id, required TractorHeadWriteData data});

  Future<TractorHeadModel> deactivateTractorHead({required String companyId, required String id});

  Future<TractorHeadModel> reactivateTractorHead({required String companyId, required String id});

  Future<TrailerModel> addTrailer({required TrailerWriteData data});

  Future<TrailerModel> editTrailer({required String id, required TrailerWriteData data});

  Future<TrailerModel> deactivateTrailer({required String companyId, required String id});

  Future<TrailerModel> reactivateTrailer({required String companyId, required String id});
}

class SupabaseFleetRemoteDataSource implements FleetRemoteDataSource {
  final SupabaseClient client;

  const SupabaseFleetRemoteDataSource(this.client);

  @override
  Future<List<TractorHeadModel>> getTractorHeads({required String companyId}) async {
    final rows = await client.from(TractorHeadDbFields.tableName).select(TractorHeadDbFields.allColumns).eq(DbCommonFields.companyId, companyId).order(TractorHeadDbFields.plateNumber);
    return rows.map((row) => TractorHeadModel.fromMap(Map<String, dynamic>.from(row))).toList();
  }

  @override
  Future<List<TrailerModel>> getTrailers({required String companyId}) async {
    final rows = await client.from(TrailerDbFields.tableName).select(TrailerDbFields.allColumns).eq(DbCommonFields.companyId, companyId).order(TrailerDbFields.plateNumber);
    return rows.map((row) => TrailerModel.fromMap(Map<String, dynamic>.from(row))).toList();
  }

  @override
  Future<TractorHeadModel> getTractorHeadById({required String companyId, required String id}) async {
    final row = await client.from(TractorHeadDbFields.tableName).select(TractorHeadDbFields.allColumns).eq(DbCommonFields.id, id).eq(DbCommonFields.companyId, companyId).single();
    return TractorHeadModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TrailerModel> getTrailerById({required String companyId, required String id}) async {
    final row = await client.from(TrailerDbFields.tableName).select(TrailerDbFields.allColumns).eq(DbCommonFields.id, id).eq(DbCommonFields.companyId, companyId).single();
    return TrailerModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TractorHeadModel> addTractorHead({required TractorHeadWriteData data}) async {
    final row = await client.from(TractorHeadDbFields.tableName).insert(data.toInsertMap()).select(TractorHeadDbFields.allColumns).single();
    return TractorHeadModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TractorHeadModel> saveTractorHead({required String id, required TractorHeadWriteData data}) async {
    final row = await client.from(TractorHeadDbFields.tableName).update(data.toUpdateMap()).eq(DbCommonFields.id, id).eq(DbCommonFields.companyId, data.companyId).select(TractorHeadDbFields.allColumns).single();
    return TractorHeadModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TractorHeadModel> deactivateTractorHead({required String companyId, required String id}) async {
    final row = await client.from(TractorHeadDbFields.tableName).update({DbCommonFields.isActive: false, DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString()}).eq(DbCommonFields.id, id).eq(DbCommonFields.companyId, companyId).select(TractorHeadDbFields.allColumns).single();
    return TractorHeadModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TractorHeadModel> reactivateTractorHead({required String companyId, required String id}) async {
    final row = await client.from(TractorHeadDbFields.tableName).update({DbCommonFields.isActive: true, DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString()}).eq(DbCommonFields.id, id).eq(DbCommonFields.companyId, companyId).select(TractorHeadDbFields.allColumns).single();
    return TractorHeadModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TrailerModel> addTrailer({required TrailerWriteData data}) async {
    final row = await client.from(TrailerDbFields.tableName).insert(data.toInsertMap()).select(TrailerDbFields.allColumns).single();
    return TrailerModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TrailerModel> editTrailer({required String id, required TrailerWriteData data}) async {
    final row = await client.from(TrailerDbFields.tableName).update(data.toUpdateMap()).eq(DbCommonFields.id, id).eq(DbCommonFields.companyId, data.companyId).select(TrailerDbFields.allColumns).single();
    return TrailerModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TrailerModel> deactivateTrailer({required String companyId, required String id}) async {
    final row = await client.from(TrailerDbFields.tableName).update({DbCommonFields.isActive: false, DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString()}).eq(DbCommonFields.id, id).eq(DbCommonFields.companyId, companyId).select(TrailerDbFields.allColumns).single();
    return TrailerModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TrailerModel> reactivateTrailer({required String companyId, required String id}) async {
    final row = await client.from(TrailerDbFields.tableName).update({DbCommonFields.isActive: true, DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString()}).eq(DbCommonFields.id, id).eq(DbCommonFields.companyId, companyId).select(TrailerDbFields.allColumns).single();
    return TrailerModel.fromMap(Map<String, dynamic>.from(row));
  }
}
