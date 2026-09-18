import '../entities/fleet_license_document.dart';
import '../entities/fleet_license_document_file.dart';
import '../entities/fleet_license_document_file_side.dart';

final class FleetLicenseDocumentPolicy {
  const FleetLicenseDocumentPolicy();

  bool canCreateWithSide(FleetLicenseDocumentFileSide side) {
    return switch (side) {
      FleetLicenseDocumentFileSide.front ||
      FleetLicenseDocumentFileSide.back ||
      FleetLicenseDocumentFileSide.combined => true,
    };
  }

  bool canAddFile(
    FleetLicenseDocument document,
    FleetLicenseDocumentFileSide side,
  ) {
    if (!document.isActive) return false;
    if (document.combinedFile != null) return false;
    if (side == FleetLicenseDocumentFileSide.combined) return false;
    return document.fileFor(side) == null;
  }

  bool canReplaceFile(
    FleetLicenseDocument document,
    FleetLicenseDocumentFile file,
  ) {
    if (!document.isActive || !file.isActive) return false;
    if (file.companyId != document.companyId ||
        file.licenseDocumentId != document.id) {
      return false;
    }
    return document.fileFor(file.side)?.id == file.id;
  }

  bool canRemove(FleetLicenseDocument document) {
    return document.isActive;
  }
}
