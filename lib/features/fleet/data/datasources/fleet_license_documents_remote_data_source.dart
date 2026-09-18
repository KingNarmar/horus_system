import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/fleet_asset_type.dart';
import '../../domain/entities/fleet_license_document_target.dart';
import '../constants/fleet_license_document_db_contract.dart';
import '../models/fleet_license_document_model.dart';

abstract class FleetLicenseDocumentsRemoteDataSource {
  Future<FleetLicenseDocumentModel?> getActiveDocument({
    required FleetLicenseDocumentTarget target,
  });

  Future<FleetLicenseDocumentModel> getActiveDocumentById({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  });

  Future<FleetLicenseDocumentModel> createDocument({
    required FleetLicenseDocumentTarget target,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
    String? licenseExpiryDate,
  });

  Future<FleetLicenseDocumentModel> replaceDocument({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
    String? licenseExpiryDate,
  });

  Future<void> removeDocument({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  });
}

final class SupabaseFleetLicenseDocumentsRemoteDataSource
    implements FleetLicenseDocumentsRemoteDataSource {
  final SupabaseClient client;

  const SupabaseFleetLicenseDocumentsRemoteDataSource(this.client);

  @override
  Future<FleetLicenseDocumentModel?> getActiveDocument({
    required FleetLicenseDocumentTarget target,
  }) async {
    var query = client
        .from(FleetLicenseDocumentDbFields.tableName)
        .select(FleetLicenseDocumentDbFields.allColumns)
        .eq(DbCommonFields.companyId, target.companyId)
        .isFilter(FleetLicenseDocumentDbFields.removedAt, null);

    query = switch (target.assetType) {
      FleetAssetType.tractorHead => query.eq(
        FleetLicenseDocumentDbFields.tractorHeadId,
        target.assetId,
      ),
      FleetAssetType.trailer => query.eq(
        FleetLicenseDocumentDbFields.trailerId,
        target.assetId,
      ),
    };

    final rows = await query
        .order(FleetLicenseDocumentDbFields.uploadedAt, ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return FleetLicenseDocumentModel.fromMap(
      Map<String, dynamic>.from(rows.first),
    );
  }

  @override
  Future<FleetLicenseDocumentModel> getActiveDocumentById({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  }) async {
    var query = client
        .from(FleetLicenseDocumentDbFields.tableName)
        .select(FleetLicenseDocumentDbFields.allColumns)
        .eq(DbCommonFields.companyId, target.companyId)
        .eq(DbCommonFields.id, documentId)
        .isFilter(FleetLicenseDocumentDbFields.removedAt, null);

    query = switch (target.assetType) {
      FleetAssetType.tractorHead => query.eq(
        FleetLicenseDocumentDbFields.tractorHeadId,
        target.assetId,
      ),
      FleetAssetType.trailer => query.eq(
        FleetLicenseDocumentDbFields.trailerId,
        target.assetId,
      ),
    };

    final row = await query.single();
    return FleetLicenseDocumentModel.fromMap(
      Map<String, dynamic>.from(row),
    );
  }

  @override
  Future<FleetLicenseDocumentModel> createDocument({
    required FleetLicenseDocumentTarget target,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
    String? licenseExpiryDate,
  }) async {
    final result = await client.rpc(
      FleetLicenseDocumentDbRpcs.create,
      params: _mutationParams(
        target: target,
        storageReference: storageReference,
        originalFileName: originalFileName,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        licenseExpiryDate: licenseExpiryDate,
      ),
    );
    return FleetLicenseDocumentModel.fromMap(_rpcMap(result));
  }

  @override
  Future<FleetLicenseDocumentModel> replaceDocument({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
    String? licenseExpiryDate,
  }) async {
    final params = _mutationParams(
      target: target,
      storageReference: storageReference,
      originalFileName: originalFileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      licenseExpiryDate: licenseExpiryDate,
    );
    params[FleetLicenseDocumentDbRpcParams.documentId] = documentId;
    final result = await client.rpc(
      FleetLicenseDocumentDbRpcs.replace,
      params: params,
    );
    return FleetLicenseDocumentModel.fromMap(_rpcMap(result));
  }

  @override
  Future<void> removeDocument({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  }) async {
    await client.rpc(
      FleetLicenseDocumentDbRpcs.remove,
      params: {
        FleetLicenseDocumentDbRpcParams.companyId: target.companyId,
        FleetLicenseDocumentDbRpcParams.assetType: target.assetType.value,
        FleetLicenseDocumentDbRpcParams.assetId: target.assetId,
        FleetLicenseDocumentDbRpcParams.documentId: documentId,
      },
    );
  }

  Map<String, dynamic> _mutationParams({
    required FleetLicenseDocumentTarget target,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
    required String? licenseExpiryDate,
  }) {
    return {
      FleetLicenseDocumentDbRpcParams.companyId: target.companyId,
      FleetLicenseDocumentDbRpcParams.assetType: target.assetType.value,
      FleetLicenseDocumentDbRpcParams.assetId: target.assetId,
      FleetLicenseDocumentDbRpcParams.storageReference: storageReference,
      FleetLicenseDocumentDbRpcParams.originalFileName: originalFileName,
      FleetLicenseDocumentDbRpcParams.mimeType: mimeType,
      FleetLicenseDocumentDbRpcParams.sizeBytes: sizeBytes,
      FleetLicenseDocumentDbRpcParams.licenseExpiryDate: licenseExpiryDate,
    };
  }

  Map<String, dynamic> _rpcMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Invalid Fleet license document RPC response.');
  }
}
