enum FleetAssetType { tractorHead, trailer }

extension FleetAssetTypeX on FleetAssetType {
  String get value {
    return switch (this) {
      FleetAssetType.tractorHead => 'tractor_head',
      FleetAssetType.trailer => 'trailer',
    };
  }
}
