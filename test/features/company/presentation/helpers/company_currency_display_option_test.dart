import 'package:flutter/widgets.dart';
import 'package:horus_system/features/company/presentation/helpers/company_currency_display_option.dart';
import 'package:test/test.dart';

void main() {
  test('resolves AED with localized names and searchable aliases', () {
    final englishOptions = CompanyCurrencyDisplayResolver.resolveAll(
      const Locale('en'),
    );
    final arabicOptions = CompanyCurrencyDisplayResolver.resolveAll(
      const Locale('ar'),
    );

    final englishAed = englishOptions.singleWhere(
      (option) => option.value == 'AED',
    );
    final arabicAed = arabicOptions.singleWhere(
      (option) => option.value == 'AED',
    );

    expect(englishAed.englishName, isNotEmpty);
    expect(englishAed.arabicName, isNotEmpty);
    expect(arabicAed.localizedName, arabicAed.arabicName);
    expect(englishAed.matches('AED'), isTrue);
    expect(englishAed.matches(englishAed.englishName), isTrue);
    expect(englishAed.matches(englishAed.arabicName), isTrue);
  });

  test('preserves a valid selected code even when display data is unavailable', () {
    final options = CompanyCurrencyDisplayResolver.resolveAll(
      const Locale('en'),
      includeCurrencyCode: 'ZZZ',
    );

    final preserved = options.singleWhere((option) => option.value == 'ZZZ');

    expect(preserved.localizedName, 'ZZZ');
    expect(preserved.matches('zzz'), isTrue);
  });
}
