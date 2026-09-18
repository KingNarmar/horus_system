import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/fleet_license_document_file.dart';
import '../../domain/entities/fleet_license_document_file_side.dart';

final class FleetLicenseDocumentFileModel {
  final String id;
  final String companyId;
  final String licenseDocumentId;
  final FleetLicenseDocumentFileSide side;
  final String storageReference;
  final String originalFileName;
  final String mimeType;
  final int sizeBytes;
  final String? uploadedBy;
  final DateTime uploadedAt;
  final String? removedBy;
  final DateTime? removedAt;
  final String? replacesFileId;

  const FleetLicenseDocumentFileModel({
    required this.id,
    required this.companyId,
    required this.licenseDocumentId,
    required this.side,
    required this.storageReference,
    required this.originalFileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedAt,
    this.uploadedBy,
    this.removedBy,
    this.removedAt,
    this.replacesFileId,
  });

  factory FleetLicenseDocumentFileModel.fromMap(Map<String, dynamic> map) {
    return FleetLicenseDocumentFileModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      licenseDocumentId: map['license_document_id'] as String,
      side: FleetLicenseDocumentFileSide.fromValue(map['side'] as String),
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
      replacesFileId: map['replaces_file_id'] as String?,
    );
  }

  FleetLicenseDocumentFile toEntity() {
    return FleetLicenseDocumentFile(
      id: id,
      companyId: companyId,
      licenseDocumentId: licenseDocumentId,
      side: side,
      originalFileName: originalFileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      uploadedBy: uploadedBy,
      uploadedAt: uploadedAt,
      removedBy: removedBy,
      removedAt: removedAt,
      replacesFileId: replacesFileId,
    );
  }
}
