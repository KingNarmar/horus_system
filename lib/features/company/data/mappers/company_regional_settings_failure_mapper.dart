import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../domain/failures/company_failure_codes.dart';
import '../constants/company_rpc_error_codes.dart';

abstract final class CompanyRegionalSettingsFailureMapper {
  static Failure fromPostgrest(PostgrestException error) {
    return switch (error.code) {
      CompanyRpcErrorCodes.settingsPermissionDenied => const PermissionFailure(
        code: CompanyFailureCodes.permissionSettingsManagement,
      ),
      CompanyRpcErrorCodes.baseCurrencyInvalid => const ValidationFailure(
        code: CompanyFailureCodes.validationBaseCurrencyInvalid,
      ),
      CompanyRpcErrorCodes.baseCurrencyFractionDigitsInvalid =>
        const ValidationFailure(
          code: CompanyFailureCodes.validationBaseCurrencyFractionDigitsInvalid,
        ),
      CompanyRpcErrorCodes.businessTimezoneInvalid => const ValidationFailure(
        code: CompanyFailureCodes.validationBusinessTimezoneInvalid,
      ),
      CompanyRpcErrorCodes.companyNotFound => const NotFoundFailure(
        code: CompanyFailureCodes.notFound,
      ),
      CompanyRpcErrorCodes.baseCurrencyLocked => const ConflictFailure(
        code: CompanyFailureCodes.conflictBaseCurrencyLocked,
      ),
      CompanyRpcErrorCodes.regionalSettingsNotConfigured =>
        const ConflictFailure(
          code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        ),
      _ => const ServerFailure(code: FailureCodes.serverError),
    };
  }
}
