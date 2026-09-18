import 'fleet_license_document_file_side.dart';

final class FleetLicenseDocumentFile {
  final String id;
  final String companyId;
  final String licenseDocumentId;
  final FleetLicenseDocumentFileSide side;
  final String originalFileName;
  final String mimeType;
  final int sizeBytes;
  final String? uploadedBy;
  final DateTime uploadedAt;
  final String? removedBy;
  final DateTime? removedAt;
  final String? replacesFileId;

  const FleetLicenseDocumentFile({
    required this.id,
    required this.companyId,
    required this.licenseDocumentId,
    required this.side,
    required this.originalFileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedAt,
    this.uploadedBy,
    this.removedBy,
    this.removedAt,
    this.replacesFileId,
  });

  bool get isActive => removedAt == null;
}
