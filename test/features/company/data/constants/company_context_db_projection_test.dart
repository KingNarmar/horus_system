import 'package:horus_system/core/data/constants/db_common_fields.dart';
import 'package:horus_system/features/company/data/constants/company_context_db_projection.dart';
import 'package:horus_system/features/company/data/constants/company_db_fields.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyContextDbProjection', () {
    test('includes regional settings required by financial modules', () {
      expect(
        CompanyContextDbProjection.companyFields,
        containsAll(const [
          CompanyDbFields.baseCurrencyCode,
          CompanyDbFields.baseCurrencyFractionDigits,
          CompanyDbFields.businessTimezone,
        ]),
      );
    });

    test('keeps membership and active-company filters company scoped', () {
      expect(
        CompanyContextDbProjection.membershipSelect,
        contains('${CompanyDbFields.companiesTable}!inner('),
      );
      expect(
        CompanyContextDbProjection.activeCompanyFilter,
        '${CompanyDbFields.companiesTable}.${DbCommonFields.isActive}',
      );
    });
  });
}
