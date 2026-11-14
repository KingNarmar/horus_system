import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;

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
      return const NotFoundFailure(code: BusinessDocumentFailureCodes.notFound);
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

    return const ServerFailure(code: BusinessDocumentFailureCodes.storageError);
  }

  Failure fromReservation(PostgrestException error) {
    if (error.code == 'P2860' &&
        error.message == BusinessDocumentFailureCodes.quotaReached) {
      return const ConflictFailure(
        code: BusinessDocumentFailureCodes.quotaReached,
      );
    }
    return switch (error.code) {
      '42501' => const PermissionFailure(
        code: BusinessDocumentFailureCodes.permissionAccess,
      ),
      'P2861' || 'P2862' => const ServerFailure(
        code: BusinessDocumentFailureCodes.quotaUnavailable,
      ),
      'P2871' => const ValidationFailure(
        code: BusinessDocumentFailureCodes.validationLocationInvalid,
      ),
      'P2872' || 'P2873' || 'P2874' => const ConflictFailure(
        code: BusinessDocumentFailureCodes.reservationConflict,
      ),
      _ => const ServerFailure(
        code: BusinessDocumentFailureCodes.storageError,
      ),
    };
  }

  Failure fromUnexpected(Object _) {
    return const UnexpectedFailure(
      code: BusinessDocumentFailureCodes.unexpectedError,
    );
  }
}
