import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/fleet_asset_type.dart';
import '../../domain/entities/fleet_license_document_file_side.dart';
import '../../domain/entities/fleet_license_document_target.dart';
import '../constants/fleet_license_document_db_contract.dart';
import '../models/fleet_license_document_file_model.dart';
import '../models/fleet_license_document_model.dart';

abstract class FleetLicenseDocumentsRemoteDataSource {
  Future<FleetLicenseDocumentModel?> getActiveDocument({
    required FleetLicenseDocumentTarget target,
  });

  Future<FleetLicenseDocumentModel> getActiveDocumentById({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  });

  Future<String> createDocumentWithFile({
    required FleetLicenseDocumentTarget target,
    required FleetLicenseDocumentFileSide side,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
    String? licenseExpiryDate,
  });

  Future<void> addDocumentFile({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required FleetLicenseDocumentFileSide side,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
    String? licenseExpiryDate,
  });

  Future<void> replaceDocumentFile({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String fileId,
    required FleetLicenseDocumentFileSide side,
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

    final base = FleetLicenseDocumentModel.fromMap(
      Map<String, dynamic>.from(rows.first),
    );
    return _withActiveFiles(base);
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
    final base = FleetLicenseDocumentModel.fromMap(
      Map<String, dynamic>.from(row),
    );
    return _withActiveFiles(base);
  }

  @override
  Future<String> createDocumentWithFile({
    required FleetLicenseDocumentTarget target,
    required FleetLicenseDocumentFileSide side,
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
        side: side,
        storageReference: storageReference,
        originalFileName: originalFileName,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        licenseExpiryDate: licenseExpiryDate,
      ),
    );
    return _rpcUuid(result);
  }

  @override
  Future<void> addDocumentFile({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required FleetLicenseDocumentFileSide side,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
    String? licenseExpiryDate,
  }) async {
    final params = _mutationParams(
      target: target,
      side: side,
      storageReference: storageReference,
      originalFileName: originalFileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      licenseExpiryDate: licenseExpiryDate,
    );
    params[FleetLicenseDocumentDbRpcParams.documentId] = documentId;
    await client.rpc(FleetLicenseDocumentDbRpcs.addFile, params: params);
  }

  @override
  Future<void> replaceDocumentFile({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String fileId,
    required FleetLicenseDocumentFileSide side,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
    String? licenseExpiryDate,
  }) async {
    final params = _mutationParams(
      target: target,
      side: side,
      storageReference: storageReference,
      originalFileName: originalFileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      licenseExpiryDate: licenseExpiryDate,
    );
    params[FleetLicenseDocumentDbRpcParams.documentId] = documentId;
    params[FleetLicenseDocumentDbRpcParams.fileId] = fileId;
    await client.rpc(FleetLicenseDocumentDbRpcs.replaceFile, params: params);
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

  Future<FleetLicenseDocumentModel> _withActiveFiles(
    FleetLicenseDocumentModel document,
  ) async {
    final rows = await client
        .from(FleetLicenseDocumentFileDbFields.tableName)
        .select(FleetLicenseDocumentFileDbFields.allColumns)
        .eq(DbCommonFields.companyId, document.companyId)
        .eq(FleetLicenseDocumentFileDbFields.licenseDocumentId, document.id)
        .isFilter(FleetLicenseDocumentFileDbFields.removedAt, null)
        .order(FleetLicenseDocumentFileDbFields.uploadedAt);

    final files = rows
        .map(
          (row) => FleetLicenseDocumentFileModel.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList(growable: false);
    return document.copyWithFiles(files);
  }

  Map<String, dynamic> _mutationParams({
    required FleetLicenseDocumentTarget target,
    required FleetLicenseDocumentFileSide side,
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
      FleetLicenseDocumentDbRpcParams.fileSide: side.value,
      FleetLicenseDocumentDbRpcParams.storageReference: storageReference,
      FleetLicenseDocumentDbRpcParams.originalFileName: originalFileName,
      FleetLicenseDocumentDbRpcParams.mimeType: mimeType,
      FleetLicenseDocumentDbRpcParams.sizeBytes: sizeBytes,
      FleetLicenseDocumentDbRpcParams.licenseExpiryDate: licenseExpiryDate,
    };
  }

  String _rpcUuid(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    throw const FormatException('Invalid Fleet license document RPC response.');
  }
}
