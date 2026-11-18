import '../entities/company_brand_logo_file.dart';
import '../failures/company_branding_failure_codes.dart';

/// Pure validation mirrors the private Storage bucket's immutable contract.
abstract final class CompanyBrandLogoPolicy {
  static const int maximumBytes = 2 * 1024 * 1024;

  static String? validate(CompanyBrandLogoFile file) {
    if (file.bytes.isEmpty) {
      return CompanyBrandingFailureCodes.imageEmpty;
    }
    if (file.bytes.length > maximumBytes) {
      return CompanyBrandingFailureCodes.imageTooLarge;
    }
    if (extensionFor(file) == null) {
      return CompanyBrandingFailureCodes.imageUnsupported;
    }
    return null;
  }

  /// Reject mismatched extensions and magic bytes; do not trust MIME guesses.
  static String? extensionFor(CompanyBrandLogoFile file) {
    final filename = file.fileName.toLowerCase().trim();
    final extension = filename.split('.').last;
    final bytes = file.bytes;

    if (extension == 'png' &&
        bytes.length >= 8 &&
        _startsWith(bytes, [137, 80, 78, 71, 13, 10, 26, 10])) {
      return 'png';
    }
    if ((extension == 'jpg' || extension == 'jpeg') &&
        bytes.length >= 3 &&
        _startsWith(bytes, [255, 216, 255])) {
      return extension;
    }
    if (extension == 'webp' &&
        bytes.length >= 12 &&
        _startsWith(bytes, [82, 73, 70, 70]) &&
        bytes[8] == 87 &&
        bytes[9] == 69 &&
        bytes[10] == 66 &&
        bytes[11] == 80) {
      return 'webp';
    }
    return null;
  }

  static bool _startsWith(List<int> data, List<int> prefix) {
    for (var index = 0; index < prefix.length; index++) {
      if (data[index] != prefix[index]) return false;
    }
    return true;
  }
}
