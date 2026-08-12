import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/customer_statements/data/constants/customer_statements_db_constants.dart';
import 'package:horus_system/features/customer_statements/data/mappers/customer_statements_failure_mapper.dart';
import 'package:horus_system/features/customer_statements/domain/failures/customer_statement_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  test('maps permission denial without raw DB text', () {
    final failure = CustomerStatementsFailureMapper.fromPostgrest(
      const PostgrestException(
        message: 'internal permission detail',
        code: CustomerStatementsRpcErrorCodes.permissionDenied,
      ),
    );

    expect(failure, isA<PermissionFailure>());
    expect(failure.code, CustomerStatementFailureCodes.permissionView);
    expect(failure.message, isNull);
  });

  test('maps invalid range and missing customer to typed failures', () {
    final range = CustomerStatementsFailureMapper.fromPostgrest(
      const PostgrestException(
        message: 'range',
        code: CustomerStatementsRpcErrorCodes.invalidDateRange,
      ),
    );
    final customer = CustomerStatementsFailureMapper.fromPostgrest(
      const PostgrestException(
        message: 'customer',
        code: CustomerStatementsRpcErrorCodes.customerNotFound,
      ),
    );

    expect(range, isA<ValidationFailure>());
    expect(range.code, CustomerStatementFailureCodes.validationDateRange);
    expect(customer, isA<NotFoundFailure>());
    expect(customer.code, CustomerStatementFailureCodes.customerNotFound);
  });

  test('maps missing company to company not-found failure', () {
    final failure = CustomerStatementsFailureMapper.fromPostgrest(
      const PostgrestException(
        message: 'company',
        code: CustomerStatementsRpcErrorCodes.companyNotFound,
      ),
    );

    expect(failure, isA<NotFoundFailure>());
    expect(failure.code, CompanyFailureCodes.notFound);
  });

  test('maps regional settings to company conflict', () {
    final failure = CustomerStatementsFailureMapper.fromPostgrest(
      const PostgrestException(
        message: 'regional',
        code: CustomerStatementsRpcErrorCodes.regionalSettingsNotConfigured,
      ),
    );

    expect(failure, isA<ConflictFailure>());
    expect(
      failure.code,
      CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
    );
  });

  test('sanitizes unknown persistence errors', () {
    final failure = CustomerStatementsFailureMapper.fromPostgrest(
      const PostgrestException(
        message: 'secret backend details',
        code: 'XX999',
        details: 'private details',
      ),
    );

    expect(failure, isA<ServerFailure>());
    expect(failure.code, FailureCodes.serverError);
    expect(failure.message, isNull);
  });
}
