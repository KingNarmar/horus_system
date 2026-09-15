import 'package:supabase_flutter/supabase_flutter.dart' show StorageException;

import '../../../errors/common_failures.dart';
import '../../../errors/failure.dart';
import '../../domain/failures/business_document_failure_codes.dart';

final class BusinessDocumentStorageFailureMapper {
  const BusinessDocumentStorageFailureMapper();

  Failure fromStorage(StorageException error) {
    final statusCode = error.statusCode;
    final message = error.message.toLowerCase();

    if (statusCode == '401' || statusCode == '403') {
      return const PermissionFailure(
        code: BusinessDocumentFailureCodes.permissionAccess,
      );
    }

    if (statusCode == '404') {
      return const NotFoundFailure(
        code: BusinessDocumentFailureCodes.notFound,
      );
    }

    if (statusCode == '409') {
      return const ConflictFailure(
        code: BusinessDocumentFailureCodes.conflictAlreadyExists,
      );
    }

    if (statusCode == '413' || message.contains('too large')) {
      return const ValidationFailure(
        code: BusinessDocumentFailureCodes.validationFileTooLarge,
      );
    }

    if (statusCode == '415' ||
        message.contains('mime') ||
        message.contains('content type')) {
      return const ValidationFailure(
        code: BusinessDocumentFailureCodes.validationFileTypeUnsupported,
      );
    }

    return const ServerFailure(
      code: BusinessDocumentFailureCodes.storageError,
    );
  }

  Failure fromUnexpected(Object _) {
    return const UnexpectedFailure(
      code: BusinessDocumentFailureCodes.unexpectedError,
    );
  }
}
