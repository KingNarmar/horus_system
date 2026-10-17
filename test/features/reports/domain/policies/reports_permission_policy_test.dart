import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/reports/domain/policies/reports_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  test('open invoice balances use the financial report role policy', () {
    for (final role in CompanyRole.values) {
      expect(
        ReportsPermissionPolicy.canViewOpenInvoicesReport(role),
        ReportsPermissionPolicy.canViewFinancialReports(role),
      );
    }
    expect(
      ReportsPermissionPolicy.canViewOpenInvoicesReport(
        CompanyRole.operations,
      ),
      isFalse,
    );
    expect(
      ReportsPermissionPolicy.canViewOpenInvoicesReport(CompanyRole.viewer),
      isFalse,
    );
  });
}
