import '../../domain/entities/fleet_asset_type.dart';

abstract final class FleetLicenseDocumentStorageSegments {
  static const documentKind = 'license';

  static String scopeFor(FleetAssetType assetType) {
    return switch (assetType) {
      FleetAssetType.tractorHead => 'tractor-heads',
      FleetAssetType.trailer => 'trailers',
    };
  }
}
