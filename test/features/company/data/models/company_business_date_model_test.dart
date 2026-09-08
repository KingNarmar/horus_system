import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/company/data/models/company_business_date_model.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyBusinessDateModel', () {
    test('parses an exact PostgreSQL date as a BusinessDate', () {
      final model = CompanyBusinessDateModel.fromValue('2026-08-05');

      expect(model.value, BusinessDate(year: 2026, month: 8, day: 5));
    });

    test('rejects timestamps and malformed dates', () {
      expect(
        () => CompanyBusinessDateModel.fromValue('2026-08-05T00:00:00.000Z'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => CompanyBusinessDateModel.fromValue('2026-02-30'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
