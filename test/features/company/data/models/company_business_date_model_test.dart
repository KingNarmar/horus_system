import 'package:horus_system/features/company/data/models/company_business_date_model.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyBusinessDateModel', () {
    test(
      'parses an exact PostgreSQL date without local timezone conversion',
      () {
        final model = CompanyBusinessDateModel.fromValue('2026-08-05');

        expect(model.value, DateTime.utc(2026, 8, 5));
        expect(model.value.isUtc, isTrue);
      },
    );

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
