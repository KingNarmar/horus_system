import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/utils/db_date.dart';
import '../../../../core/documents/domain/entities/business_document_reference.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../domain/entities/driver_compensation_write_data.dart';
import '../constants/driver_compensation_db_fields.dart';
import '../mappers/driver_compensation_mapper.dart';
import '../models/driver_compensation_model.dart';

abstract class DriverCompensationRemoteDataSource {
  Future<List<DriverCompensationModel>> getHistory({
    required String companyId,
    required String driverId,
  });

  Future<DriverCompensationModel> getById({
    required String companyId,
    required String revisionId,
    required String driverId,
  });

  Future<DriverCompensationModel> createRevision({
    required String revisionId,
    required DriverCompensationWriteData data,
    BusinessDocumentReference? contractDocumentReference,
  });

  Future<DriverCompensationModel> endRevision({
    required String companyId,
    required String revisionId,
    required String driverId,
    required BusinessDate effectiveTo,
  });

  Future<DriverCompensationModel> attachContractDocument({
    required String companyId,
    required String revisionId,
    required String driverId,
    required BusinessDocumentReference reference,
  });
}

final class SupabaseDriverCompensationRemoteDataSource
    implements DriverCompensationRemoteDataSource {
  static const String _columns = DriverCompensationDbFields.allColumns;

  final SupabaseClient client;

  const SupabaseDriverCompensationRemoteDataSource(this.client);

  @override
  Future<List<DriverCompensationModel>> getHistory({
    required String companyId,
    required String driverId,
  }) async {
    final response = await client
        .from(DriverCompensationDbFields.tableName)
        .select(_columns)
        .eq(DriverCompensationDbFields.companyId, companyId)
        .eq(DriverCompensationDbFields.driverId, driverId)
        .order(DriverCompensationDbFields.effectiveFrom, ascending: false);

    return response
        .map(
          (item) =>
              DriverCompensationModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  @override
  Future<DriverCompensationModel> getById({
    required String companyId,
    required String revisionId,
    required String driverId,
  }) async {
    final response = await client
        .from(DriverCompensationDbFields.tableName)
        .select(_columns)
        .eq(DriverCompensationDbFields.id, revisionId)
        .eq(DriverCompensationDbFields.companyId, companyId)
        .eq(DriverCompensationDbFields.driverId, driverId)
        .single();

    return DriverCompensationModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<DriverCompensationModel> createRevision({
    required String revisionId,
    required DriverCompensationWriteData data,
    BusinessDocumentReference? contractDocumentReference,
  }) async {
    final response = await client
        .from(DriverCompensationDbFields.tableName)
        .insert(
          data.toInsertMap(
            revisionId: revisionId,
            contractDocumentReference: contractDocumentReference,
          ),
        )
        .select(_columns)
        .single();

    return DriverCompensationModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<DriverCompensationModel> endRevision({
    required String companyId,
    required String revisionId,
    required String driverId,
    required BusinessDate effectiveTo,
  }) async {
    final response = await client
        .from(DriverCompensationDbFields.tableName)
        .update({
          DriverCompensationDbFields.effectiveTo: DbDate.encode(effectiveTo),
        })
        .eq(DriverCompensationDbFields.id, revisionId)
        .eq(DriverCompensationDbFields.companyId, companyId)
        .eq(DriverCompensationDbFields.driverId, driverId)
        .select(_columns)
        .single();

    return DriverCompensationModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<DriverCompensationModel> attachContractDocument({
    required String companyId,
    required String revisionId,
    required String driverId,
    required BusinessDocumentReference reference,
  }) async {
    final response = await client
        .from(DriverCompensationDbFields.tableName)
        .update({
          DriverCompensationDbFields.contractDocumentReference: reference.value,
        })
        .eq(DriverCompensationDbFields.id, revisionId)
        .eq(DriverCompensationDbFields.companyId, companyId)
        .eq(DriverCompensationDbFields.driverId, driverId)
        .select(_columns)
        .single();

    return DriverCompensationModel.fromMap(Map<String, dynamic>.from(response));
  }
}
