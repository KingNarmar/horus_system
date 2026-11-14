import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../subscriptions/domain/failures/quota_failure_codes.dart';
import '../../domain/failures/trip_document_failure_codes.dart';
import '../constants/trip_document_db_contract.dart';

final class TripDocumentRepositoryFailureMapper {
  const TripDocumentRepositoryFailureMapper();

  Failure fromPostgrest(PostgrestException error) {
    return switch (error.code) {
      'P2860'
          when error.message == QuotaFailureCodes.businessDocumentsReached =>
        const ConflictFailure(code: QuotaFailureCodes.businessDocumentsReached),
      'P2861' ||
      'P2862' => const ServerFailure(code: QuotaFailureCodes.unavailable),
      'P2873' ||
      'P2874' ||
      'P2872' => const ConflictFailure(code: QuotaFailureCodes.unavailable),
      TripDocumentDbErrorCodes.permissionDenied => const PermissionFailure(
        code: TripDocumentFailureCodes.permissionManage,
      ),
      TripDocumentDbErrorCodes.tripNotFound ||
      TripDocumentDbErrorCodes.documentNotFound ||
      'PGRST116' => const NotFoundFailure(
        code: TripDocumentFailureCodes.notFound,
      ),
      TripDocumentDbErrorCodes.maxActiveDocuments => const ConflictFailure(
        code: TripDocumentFailureCodes.conflictMaxActiveDocuments,
      ),
      TripDocumentDbErrorCodes.evidenceRequired => const ConflictFailure(
        code: TripDocumentFailureCodes.conflictEvidenceRequired,
      ),
      TripDocumentDbErrorCodes.invalidStorageReference ||
      TripDocumentDbErrorCodes.invalidStatusTransition =>
        const ValidationFailure(code: TripDocumentFailureCodes.unexpectedError),
      _ => const ServerFailure(code: TripDocumentFailureCodes.serverError),
    };
  }

  Failure fromUnexpected(Object error) {
    return const UnexpectedFailure(
      code: TripDocumentFailureCodes.unexpectedError,
    );
  }
}
