enum FleetLicenseDocumentFileSide {
  front,
  back,
  combined;

  String get value {
    return switch (this) {
      FleetLicenseDocumentFileSide.front => 'front',
      FleetLicenseDocumentFileSide.back => 'back',
      FleetLicenseDocumentFileSide.combined => 'combined',
    };
  }

  static FleetLicenseDocumentFileSide fromValue(String value) {
    return switch (value) {
      'front' => FleetLicenseDocumentFileSide.front,
      'back' => FleetLicenseDocumentFileSide.back,
      'combined' => FleetLicenseDocumentFileSide.combined,
      _ => throw ArgumentError.value(value, 'value', 'Unknown file side'),
    };
  }
}
