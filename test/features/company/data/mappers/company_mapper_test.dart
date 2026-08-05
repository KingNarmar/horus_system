import 'package:horus_system/features/company/data/mappers/company_mapper.dart';
import 'package:horus_system/features/company/data/models/company_model.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyModel', () {
    test('maps persisted regional settings to the domain entity', () {
      final model = CompanyModel.fromMap(const {
        'id': 'company-1',
        'name': 'Horus Transport',
        'business_type': 'heavy_transport',
        'phone': '+971500000000',
        'email': 'finance@example.com',
        'country': 'AE',
        'city': 'Dubai',
        'logo_url': 'https://example.com/logo.png',
        'base_currency_code': 'AED',
        'base_currency_fraction_digits': 2,
        'business_timezone': 'Asia/Dubai',
        'is_active': true,
      });

      final entity = model.toEntity();

      expect(entity.id, 'company-1');
      expect(entity.name, 'Horus Transport');
      expect(entity.businessType, 'heavy_transport');
      expect(entity.phone, '+971500000000');
      expect(entity.email, 'finance@example.com');
      expect(entity.country, 'AE');
      expect(entity.city, 'Dubai');
      expect(entity.logoUrl, 'https://example.com/logo.png');
      expect(entity.baseCurrencyCode, 'AED');
      expect(entity.baseCurrencyFractionDigits, 2);
      expect(entity.businessTimezone, 'Asia/Dubai');
      expect(entity.hasCompleteRegionalSettings, isTrue);
      expect(entity.isActive, isTrue);
    });

    test('keeps missing regional settings explicit as null', () {
      final entity = CompanyModel.fromMap(const {
        'id': 'company-1',
        'name': 'Horus Transport',
        'is_active': true,
      }).toEntity();

      expect(entity.baseCurrencyCode, isNull);
      expect(entity.baseCurrencyFractionDigits, isNull);
      expect(entity.businessTimezone, isNull);
      expect(entity.hasCompleteRegionalSettings, isFalse);
    });
  });
}
