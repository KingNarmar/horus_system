import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/failures/reports_failure_codes.dart';
import '../constants/reports_db_constants.dart';

abstract final class ReportsFailureMapper {
  static Failure fromPostgrest(
    PostgrestException error, {
    required String permissionFailureCode,
  }) {
    return switch (error.code) {
      ReportsRpcErrorCodes.permissionDenied ||
      '42501' => PermissionFailure(code: permissionFailureCode),
      ReportsRpcErrorCodes.invalidDateRange => const ValidationFailure(
        code: ReportsFailureCodes.validationDateRange,
      ),
      ReportsRpcErrorCodes.companyNotFound => const NotFoundFailure(
        code: CompanyFailureCodes.notFound,
      ),
      ReportsRpcErrorCodes.regionalSettingsNotConfigured =>
        const ConflictFailure(
          code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        ),
      _ => const ServerFailure(code: FailureCodes.serverError),
    };
  }
}
