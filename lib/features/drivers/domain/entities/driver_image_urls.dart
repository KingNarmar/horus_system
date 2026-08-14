class DriverImageUrls {
  final String? profileImageUrl;
  final String? licenseImageUrl;
  final String? licenseBackImageUrl;
  final String? nationalIdImageUrl;
  final String? nationalIdBackImageUrl;

  const DriverImageUrls({
    this.profileImageUrl,
    this.licenseImageUrl,
    this.licenseBackImageUrl,
    this.nationalIdImageUrl,
    this.nationalIdBackImageUrl,
  });

  static const empty = DriverImageUrls();
}
