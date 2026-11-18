import 'package:horus_system/features/company/data/models/company_brand_profile_model.dart';
import 'package:test/test.dart';

void main() {
  test('company identity is mapped without leaking financial settings', () {
    final model = CompanyBrandProfileModel.fromMap(const {
      'id': 'company-1',
      'name': 'Hauling LLC',
      'updated_at': '2026-11-15T13:00:00.000123+00:00',
      'business_type': 'transport',
      'phone': '+971500000000',
      'email': 'info@example.test',
      'country': 'AE',
      'city': 'Dubai',
      'address': 'Warehouse Road',
      'tax_registration_number': null,
      'logo_url': 'companies/company-1/logos/opaque.png',
    });
    final entity = model.toEntity();
    expect(entity.companyId, 'company-1');
    expect(entity.updatedAt.microsecond, 123);
    expect(entity.logoPath, 'companies/company-1/logos/opaque.png');
    expect(entity.address, 'Warehouse Road');
    expect(entity.taxRegistrationNumber, isNull);
  });
}
