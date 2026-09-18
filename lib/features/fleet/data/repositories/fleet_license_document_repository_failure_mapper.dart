import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/failures/fleet_license_document_failure_codes.dart';
import '../constants/fleet_license_document_db_contract.dart';

final class FleetLicenseDocumentRepositoryFailureMapper {
  const FleetLicenseDocumentRepositoryFailureMapper();

  Failure fromPostgrest(PostgrestException error) {
    return switch (error.code) {
      FleetLicenseDocumentDbErrorCodes.permissionDenied =>
        const PermissionFailure(
          code: FleetLicenseDocumentFailureCodes.permissionManage,
        ),
      FleetLicenseDocumentDbErrorCodes.assetNotFound ||
      FleetLicenseDocumentDbErrorCodes.documentNotFound ||
      'PGRST116' => const NotFoundFailure(
        code: FleetLicenseDocumentFailureCodes.notFound,
      ),
      FleetLicenseDocumentDbErrorCodes.activeDocumentExists ||
      '23505' => const ConflictFailure(
        code:
            FleetLicenseDocumentFailureCodes.conflictActiveDocumentExists,
      ),
      FleetLicenseDocumentDbErrorCodes.invalidStorageReference ||
      FleetLicenseDocumentDbErrorCodes.invalidAssetType =>
        const ValidationFailure(
          code: FleetLicenseDocumentFailureCodes.unexpectedError,
        ),
      _ => const ServerFailure(
        code: FleetLicenseDocumentFailureCodes.serverError,
      ),
    };
  }

  Failure fromUnexpected(Object error) {
    return const UnexpectedFailure(
      code: FleetLicenseDocumentFailureCodes.unexpectedError,
    );
  }
}
