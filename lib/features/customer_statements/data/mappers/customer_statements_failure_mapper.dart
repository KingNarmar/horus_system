import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/failures/customer_statement_failure_codes.dart';
import '../constants/customer_statements_db_constants.dart';

abstract final class CustomerStatementsFailureMapper {
  static Failure fromPostgrest(PostgrestException error) {
    return switch (error.code) {
      CustomerStatementsRpcErrorCodes.permissionDenied ||
      '42501' => const PermissionFailure(
        code: CustomerStatementFailureCodes.permissionView,
      ),
      CustomerStatementsRpcErrorCodes.invalidDateRange =>
        const ValidationFailure(
          code: CustomerStatementFailureCodes.validationDateRange,
        ),
      CustomerStatementsRpcErrorCodes.companyNotFound =>
        const NotFoundFailure(code: CompanyFailureCodes.notFound),
      CustomerStatementsRpcErrorCodes.regionalSettingsNotConfigured =>
        const ConflictFailure(
          code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        ),
      CustomerStatementsRpcErrorCodes.customerNotFound =>
        const NotFoundFailure(
          code: CustomerStatementFailureCodes.customerNotFound,
        ),
      _ => const ServerFailure(code: FailureCodes.serverError),
    };
  }
}
