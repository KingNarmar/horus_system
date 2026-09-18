import '../entities/fleet_license_document.dart';

final class FleetLicenseDocumentPolicy {
  const FleetLicenseDocumentPolicy();

  bool canUpload(FleetLicenseDocument? activeDocument) {
    return activeDocument == null;
  }

  bool canMutate(FleetLicenseDocument document) {
    return document.isActive;
  }
}
