import '../../../errors/common_failures.dart';
import '../../../errors/failure.dart';
import '../entities/business_document_file.dart';
import '../failures/business_document_failure_codes.dart';

final class BusinessDocumentFilePolicy {
  static const int maxFileBytes = 10 * 1024 * 1024;

  static const Map<String, String> _contentTypeByExtension = {
    '.pdf': 'application/pdf',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
    '.heic': 'image/heic',
    '.heif': 'image/heif',
  };

  const BusinessDocumentFilePolicy();

  Failure? validate(BusinessDocumentFile file) {
    if (file.bytes.isEmpty) {
      return const ValidationFailure(
        code: BusinessDocumentFailureCodes.validationFileEmpty,
      );
    }

    if (file.sizeInBytes > maxFileBytes) {
      return const ValidationFailure(
        code: BusinessDocumentFailureCodes.validationFileTooLarge,
      );
    }

    final normalizedName = file.fileName.trim();
    if (normalizedName.isEmpty ||
        normalizedName.contains('/') ||
        normalizedName.contains('\\')) {
      return const ValidationFailure(
        code: BusinessDocumentFailureCodes.validationFileNameInvalid,
      );
    }

    final dotIndex = normalizedName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == normalizedName.length - 1) {
      return const ValidationFailure(
        code: BusinessDocumentFailureCodes.validationFileNameInvalid,
      );
    }

    final extension = normalizedName.substring(dotIndex).toLowerCase();
    final expectedContentType = _contentTypeByExtension[extension];
    if (expectedContentType == null) {
      return const ValidationFailure(
        code: BusinessDocumentFailureCodes.validationFileTypeUnsupported,
      );
    }

    final providedContentType = file.mimeType?.trim().toLowerCase();
    if (providedContentType != null &&
        providedContentType.isNotEmpty &&
        providedContentType != expectedContentType) {
      return const ValidationFailure(
        code: BusinessDocumentFailureCodes.validationFileTypeUnsupported,
      );
    }

    return null;
  }

  String? contentTypeFor(BusinessDocumentFile file) {
    final extension = extensionForFileName(file.fileName);
    if (extension == null) return null;
    return _contentTypeByExtension[extension];
  }

  static String? extensionForFileName(String fileName) {
    final normalizedName = fileName.trim();
    if (normalizedName.isEmpty ||
        normalizedName.contains('/') ||
        normalizedName.contains('\\')) {
      return null;
    }

    final dotIndex = normalizedName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == normalizedName.length - 1) {
      return null;
    }

    final extension = normalizedName.substring(dotIndex).toLowerCase();
    return _contentTypeByExtension.containsKey(extension) ? extension : null;
  }
}
