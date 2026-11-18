import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException, StorageException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../domain/failures/company_branding_failure_codes.dart';

final class CompanyBrandingFailureMapper {
  const CompanyBrandingFailureMapper();

  Failure fromAuth(AuthException _) =>
      const AuthFailure(code: CompanyBrandingFailureCodes.permissionDenied);

  Failure fromDatabase(PostgrestException error) => switch (error.code) {
    'P3510' || '42501' => const PermissionFailure(
      code: CompanyBrandingFailureCodes.permissionDenied,
    ),
    'P3511' => const ValidationFailure(
      code: CompanyBrandingFailureCodes.profileInvalid,
    ),
    'P3512' => const ConflictFailure(
      code: CompanyBrandingFailureCodes.profileConflict,
    ),
    'P3513' => const NotFoundFailure(
      code: CompanyBrandingFailureCodes.companyUnavailable,
    ),
    _ => const ServerFailure(code: FailureCodes.serverError),
  };

  Failure fromStorage(StorageException error) {
    if (error.statusCode == '401' || error.statusCode == '403') {
      return const PermissionFailure(
        code: CompanyBrandingFailureCodes.permissionDenied,
      );
    }
    if (error.statusCode == '413') {
      return const ValidationFailure(
        code: CompanyBrandingFailureCodes.imageTooLarge,
      );
    }
    if (error.statusCode == '415') {
      return const ValidationFailure(
        code: CompanyBrandingFailureCodes.imageUnsupported,
      );
    }
    return const ServerFailure(
      code: CompanyBrandingFailureCodes.uploadUnavailable,
    );
  }

  Failure fromUnexpected(Object _) => const UnexpectedFailure();
}
