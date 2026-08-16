import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../entities/driver_image_file.dart';

class DriverImageUploadValidator {
  static const int maxImageBytes = 5 * 1024 * 1024;
  static const Set<String> allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
    '.heif',
  };

  const DriverImageUploadValidator();

  Failure? validateUploadSet(DriverImageUploadSet? uploadSet) {
    if (uploadSet == null || !uploadSet.hasAny) return null;

    for (final image in uploadSet.images) {
      final failure = validateImage(image);
      if (failure != null) return failure;
    }

    return null;
  }

  Failure? validateImage(DriverImageFile image) {
    if (image.bytes.lengthInBytes > maxImageBytes) {
      return const ValidationFailure(
        code: FailureCodes.validationDriverImageTooLarge,
        message: 'Driver image file is too large.',
      );
    }

    if (!_isAllowedFileName(image.fileName)) {
      return const ValidationFailure(
        code: FailureCodes.validationDriverImageTypeUnsupported,
        message: 'Driver image file type is not supported.',
      );
    }

    return null;
  }

  bool _isAllowedFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return true;
    }
    final extension = fileName.substring(dotIndex).toLowerCase();
    return allowedExtensions.contains(extension);
  }
}
