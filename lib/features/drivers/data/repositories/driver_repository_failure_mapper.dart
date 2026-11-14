import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../subscriptions/domain/failures/quota_failure_codes.dart';
import '../../../../core/documents/domain/failures/business_document_failure_codes.dart';
import '../datasources/driver_images_remote_data_source.dart';

final class DriverRepositoryFailureMapper {
  const DriverRepositoryFailureMapper();

  Failure fromPostgrest(PostgrestException error) {
    if (error.code == 'P2860' &&
        error.message == QuotaFailureCodes.driversReached) {
      return const ConflictFailure(code: QuotaFailureCodes.driversReached);
    }
    if (error.code == 'P2860' &&
        error.message == QuotaFailureCodes.businessDocumentsReached) {
      return const ConflictFailure(
        code: QuotaFailureCodes.businessDocumentsReached,
      );
    }
    if (error.code == 'P2873' || error.code == 'P2874') {
      return const ServerFailure(code: QuotaFailureCodes.unavailable);
    }
    if (error.code == 'P2861' || error.code == 'P2862') {
      return const ServerFailure(code: QuotaFailureCodes.unavailable);
    }
    return const ServerFailure(code: FailureCodes.serverError);
  }

  Failure fromStorage(StorageException error) {
    final message = error.message.toLowerCase();
    final statusCode = error.statusCode;
    if (statusCode == '413' || message.contains('too large')) {
      return const ValidationFailure(
        code: FailureCodes.validationDriverImageTooLarge,
        message: 'Driver image file is too large.',
      );
    }
    if (statusCode == '415' ||
        message.contains('mime') ||
        message.contains('type')) {
      return const ValidationFailure(
        code: FailureCodes.validationDriverImageTypeUnsupported,
        message: 'Driver image file type is not supported.',
      );
    }
    return const ServerFailure(code: FailureCodes.serverError);
  }

  Failure fromUnexpected(Object error) {
    if (error is DriverDocumentCleanupPendingException) {
      return const ServerFailure(
        code: BusinessDocumentFailureCodes.cleanupPending,
      );
    }
    return const UnexpectedFailure();
  }
}
