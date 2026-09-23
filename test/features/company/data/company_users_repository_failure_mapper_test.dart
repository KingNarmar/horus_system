import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/data/repositories/company_users_repository_failure_mapper.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  const mapper = CompanyUsersRepositoryFailureMapper();

  test('maps server permission denial to company users view failure', () {
    final failure = mapper.fromPostgrest(
      PostgrestException(message: 'company_users_permission_denied'),
    );

    expect(failure, isA<PermissionFailure>());
    expect(failure.code, FailureCodes.permissionCompanyUsersView);
  });

  test('maps missing auth to sanitized company auth failure', () {
    final failure = mapper.fromPostgrest(
      PostgrestException(message: CompanyFailureCodes.authRequired),
    );

    expect(failure, isA<AuthFailure>());
    expect(failure.code, CompanyFailureCodes.authRequired);
  });
}
