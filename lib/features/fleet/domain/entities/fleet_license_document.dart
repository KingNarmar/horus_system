import 'fleet_asset_type.dart';

final class FleetLicenseDocument {
  final String id;
  final String companyId;
  final FleetAssetType assetType;
  final String assetId;
  final String originalFileName;
  final String mimeType;
  final int sizeBytes;
  final String? uploadedBy;
  final DateTime uploadedAt;
  final String? removedBy;
  final DateTime? removedAt;
  final String? replacesDocumentId;

  const FleetLicenseDocument({
    required this.id,
    required this.companyId,
    required this.assetType,
    required this.assetId,
    required this.originalFileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedAt,
    this.uploadedBy,
    this.removedBy,
    this.removedAt,
    this.replacesDocumentId,
  });

  bool get isActive => removedAt == null;
}
