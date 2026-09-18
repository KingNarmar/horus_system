import 'fleet_asset_type.dart';

final class FleetLicenseDocumentTarget {
  final String companyId;
  final FleetAssetType assetType;
  final String assetId;

  const FleetLicenseDocumentTarget({
    required this.companyId,
    required this.assetType,
    required this.assetId,
  });
}
