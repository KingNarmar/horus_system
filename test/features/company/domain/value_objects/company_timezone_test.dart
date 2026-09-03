import 'package:horus_system/features/company/domain/value_objects/company_timezone.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyTimezone', () {
    test('trims and accepts valid IANA-style timezone identifiers', () {
      expect(CompanyTimezone.tryParse(' Asia/Dubai ')?.value, 'Asia/Dubai');
      expect(CompanyTimezone.tryParse('Etc/GMT+4')?.value, 'Etc/GMT+4');
      expect(CompanyTimezone.tryParse('UTC')?.value, 'UTC');
    });

    test('rejects blank and malformed values', () {
      expect(CompanyTimezone.tryParse('   '), isNull);
      expect(CompanyTimezone.tryParse('Asia /Dubai'), isNull);
      expect(CompanyTimezone.tryParse('Asia/Dubai?'), isNull);
    });

    test('rejects values longer than the domain limit', () {
      final tooLongValue = List<String>.filled(129, 'a').join();
      expect(CompanyTimezone.tryParse(tooLongValue), isNull);
    });
  });
}
