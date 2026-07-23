import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/utils/search_text_normalizer.dart';

void main() {
  group('normalizeSearchText', () {
    test('normalizes Arabic alef variants', () {
      expect(normalizeSearchText('الإطارات'), normalizeSearchText('الاطارات'));
      expect(normalizeSearchText('أخرى'), normalizeSearchText('اخري'));
      expect(normalizeSearchText('آلات'), normalizeSearchText('الات'));
    });

    test('removes Arabic diacritics and tatweel', () {
      expect(
        normalizeSearchText('الإِطَارات'),
        normalizeSearchText('الاطارات'),
      );
      expect(normalizeSearchText('الـغرامات'), normalizeSearchText('الغرامات'));
    });

    test('keeps English search case insensitive', () {
      expect(normalizeSearchText(' Tires '), 'tires');
    });
  });
}
