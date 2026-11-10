import 'package:horus_system/features/company/data/repositories/company_command_failure_mapper.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:test/test.dart';

void main() {
  test('invite quota error is typed and not a raw backend message', () {
    final failure = const CompanyCommandFailureMapper().fromCode(
      CompanyFailureCodes.quotaCompanyUsersReached,
    );
    expect(failure.code, CompanyFailureCodes.quotaCompanyUsersReached);
    expect(failure.message, isNull);
  });
}
