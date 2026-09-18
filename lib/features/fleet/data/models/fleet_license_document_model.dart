import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/fleet_asset_type.dart';
import '../../domain/entities/fleet_license_document.dart';

final class FleetLicenseDocumentModel {
  final String id;
  final String companyId;
  final String? tractorHeadId;
  final String? trailerId;
  final String storageReference;
  final String originalFileName;
  final String mimeType;
  final int sizeBytes;
  final String? uploadedBy;
  final DateTime uploadedAt;
  final String? removedBy;
  final DateTime? removedAt;
  final String? replacesDocumentId;

  const FleetLicenseDocumentModel({
    required this.id,
    required this.companyId,
    required this.storageReference,
    required this.originalFileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedAt,
    this.tractorHeadId,
    this.trailerId,
    this.uploadedBy,
    this.removedBy,
    this.removedAt,
    this.replacesDocumentId,
  });

  factory FleetLicenseDocumentModel.fromMap(Map<String, dynamic> map) {
    final tractorHeadId = map['tractor_head_id'] as String?;
    final trailerId = map['trailer_id'] as String?;
    if ((tractorHeadId == null) == (trailerId == null)) {
      throw const FormatException('Invalid Fleet license document asset.');
    }

    return FleetLicenseDocumentModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      tractorHeadId: tractorHeadId,
      trailerId: trailerId,
      storageReference: map['storage_reference'] as String,
      originalFileName: map['original_file_name'] as String,
      mimeType: map['mime_type'] as String,
      sizeBytes: (map['size_bytes'] as num).toInt(),
      uploadedBy: map['uploaded_by'] as String?,
      uploadedAt: DbTimestamp.decode(map['uploaded_at'], field: 'uploaded_at'),
      removedBy: map['removed_by'] as String?,
      removedAt: DbTimestamp.decodeNullable(
        map['removed_at'],
        field: 'removed_at',
      ),
      replacesDocumentId: map['replaces_document_id'] as String?,
    );
  }

  FleetLicenseDocument toEntity() {
    final tractorId = tractorHeadId;
    return FleetLicenseDocument(
      id: id,
      companyId: companyId,
      assetType: tractorId != null
          ? FleetAssetType.tractorHead
          : FleetAssetType.trailer,
      assetId: tractorId ?? trailerId!,
      originalFileName: originalFileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      uploadedBy: uploadedBy,
      uploadedAt: uploadedAt,
      removedBy: removedBy,
      removedAt: removedAt,
      replacesDocumentId: replacesDocumentId,
    );
  }
}
