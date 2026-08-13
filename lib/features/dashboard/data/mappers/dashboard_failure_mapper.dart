import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/failures/dashboard_failure_codes.dart';
import '../constants/dashboard_db_constants.dart';

abstract final class DashboardFailureMapper {
  static Failure fromPostgrest(PostgrestException error) {
    return switch (error.code) {
      DashboardRpcErrorCodes.permissionDenied || '42501' =>
        const PermissionFailure(code: DashboardFailureCodes.permissionView),
      DashboardRpcErrorCodes.companyNotFound => const NotFoundFailure(
        code: CompanyFailureCodes.notFound,
      ),
      DashboardRpcErrorCodes.regionalSettingsNotConfigured =>
        const ConflictFailure(
          code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        ),
      _ => const ServerFailure(code: FailureCodes.serverError),
    };
  }
}
