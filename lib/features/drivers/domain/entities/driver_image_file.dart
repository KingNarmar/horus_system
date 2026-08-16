import 'dart:typed_data';

class DriverImageFile {
  final Uint8List bytes;
  final String fileName;
  final String? mimeType;

  const DriverImageFile({
    required this.bytes,
    required this.fileName,
    this.mimeType,
  });
}

class DriverImageUploadSet {
  final DriverImageFile? profileImage;
  final DriverImageFile? licenseFrontImage;
  final DriverImageFile? licenseBackImage;
  final DriverImageFile? nationalIdFrontImage;
  final DriverImageFile? nationalIdBackImage;

  const DriverImageUploadSet({
    this.profileImage,
    this.licenseFrontImage,
    this.licenseBackImage,
    this.nationalIdFrontImage,
    this.nationalIdBackImage,
  });

  bool get hasAny =>
      profileImage != null ||
      licenseFrontImage != null ||
      licenseBackImage != null ||
      nationalIdFrontImage != null ||
      nationalIdBackImage != null;

  Iterable<DriverImageFile> get images sync* {
    if (profileImage != null) yield profileImage!;
    if (licenseFrontImage != null) yield licenseFrontImage!;
    if (licenseBackImage != null) yield licenseBackImage!;
    if (nationalIdFrontImage != null) yield nationalIdFrontImage!;
    if (nationalIdBackImage != null) yield nationalIdBackImage!;
  }
}
