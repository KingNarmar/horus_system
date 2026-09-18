import 'fleet_asset_type.dart';
import 'fleet_license_document_file.dart';
import 'fleet_license_document_file_side.dart';

final class FleetLicenseDocument {
  final String id;
  final String companyId;
  final FleetAssetType assetType;
  final String assetId;
  final List<FleetLicenseDocumentFile> files;
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
    required this.files,
    required this.uploadedAt,
    this.uploadedBy,
    this.removedBy,
    this.removedAt,
    this.replacesDocumentId,
  });

  bool get isActive => removedAt == null;

  List<FleetLicenseDocumentFile> get activeFiles {
    return files.where((file) => file.isActive).toList(growable: false);
  }

  FleetLicenseDocumentFile? fileFor(FleetLicenseDocumentFileSide side) {
    for (final file in files) {
      if (file.isActive && file.side == side) return file;
    }
    return null;
  }

  FleetLicenseDocumentFile? get frontFile =>
      fileFor(FleetLicenseDocumentFileSide.front);

  FleetLicenseDocumentFile? get backFile =>
      fileFor(FleetLicenseDocumentFileSide.back);

  FleetLicenseDocumentFile? get combinedFile =>
      fileFor(FleetLicenseDocumentFileSide.combined);
}
