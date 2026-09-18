import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';

import '../constants/trip_document_db_contract.dart';
import '../models/trip_document_model.dart';

abstract class TripDocumentsRemoteDataSource {
  Future<List<TripDocumentModel>> getActiveDocuments({
    required String companyId,
    required String tripId,
  });

  Future<TripDocumentModel> getActiveDocumentById({
    required String companyId,
    required String tripId,
    required String documentId,
  });

  Future<TripDocumentModel> createDocument({
    required String companyId,
    required String tripId,
    required String documentKind,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
  });

  Future<TripDocumentModel> replaceDocument({
    required String companyId,
    required String tripId,
    required String documentId,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
  });

  Future<void> removeDocument({
    required String companyId,
    required String tripId,
    required String documentId,
  });
}

final class SupabaseTripDocumentsRemoteDataSource
    implements TripDocumentsRemoteDataSource {
  final SupabaseClient client;

  const SupabaseTripDocumentsRemoteDataSource(this.client);

  @override
  Future<List<TripDocumentModel>> getActiveDocuments({
    required String companyId,
    required String tripId,
  }) async {
    final rows = await client
        .from(TripDocumentDbFields.tableName)
        .select(TripDocumentDbFields.allColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(TripDocumentDbFields.tripId, tripId)
        .isFilter(TripDocumentDbFields.removedAt, null)
        .order(TripDocumentDbFields.uploadedAt, ascending: false);

    return rows
        .map((row) => TripDocumentModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<TripDocumentModel> getActiveDocumentById({
    required String companyId,
    required String tripId,
    required String documentId,
  }) async {
    final row = await client
        .from(TripDocumentDbFields.tableName)
        .select(TripDocumentDbFields.allColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(TripDocumentDbFields.tripId, tripId)
        .eq(DbCommonFields.id, documentId)
        .isFilter(TripDocumentDbFields.removedAt, null)
        .single();

    return TripDocumentModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TripDocumentModel> createDocument({
    required String companyId,
    required String tripId,
    required String documentKind,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
  }) async {
    final result = await client.rpc(
      TripDocumentDbRpcs.create,
      params: {
        TripDocumentDbRpcParams.companyId: companyId,
        TripDocumentDbRpcParams.tripId: tripId,
        TripDocumentDbRpcParams.documentKind: documentKind,
        TripDocumentDbRpcParams.storageReference: storageReference,
        TripDocumentDbRpcParams.originalFileName: originalFileName,
        TripDocumentDbRpcParams.mimeType: mimeType,
        TripDocumentDbRpcParams.sizeBytes: sizeBytes,
      },
    );

    return TripDocumentModel.fromMap(_rpcMap(result));
  }

  @override
  Future<TripDocumentModel> replaceDocument({
    required String companyId,
    required String tripId,
    required String documentId,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
  }) async {
    final result = await client.rpc(
      TripDocumentDbRpcs.replace,
      params: {
        TripDocumentDbRpcParams.companyId: companyId,
        TripDocumentDbRpcParams.tripId: tripId,
        TripDocumentDbRpcParams.documentId: documentId,
        TripDocumentDbRpcParams.storageReference: storageReference,
        TripDocumentDbRpcParams.originalFileName: originalFileName,
        TripDocumentDbRpcParams.mimeType: mimeType,
        TripDocumentDbRpcParams.sizeBytes: sizeBytes,
      },
    );

    return TripDocumentModel.fromMap(_rpcMap(result));
  }

  @override
  Future<void> removeDocument({
    required String companyId,
    required String tripId,
    required String documentId,
  }) async {
    await client.rpc(
      TripDocumentDbRpcs.remove,
      params: {
        TripDocumentDbRpcParams.companyId: companyId,
        TripDocumentDbRpcParams.tripId: tripId,
        TripDocumentDbRpcParams.documentId: documentId,
      },
    );
  }

  Map<String, dynamic> _rpcMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Invalid trip document RPC response.');
  }
}
