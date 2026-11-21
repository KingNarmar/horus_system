import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/company/domain/value_objects/company_timezone.dart';
import 'package:horus_system/features/company/presentation/helpers/company_timezone_display_option.dart';

void main() {
  group('CompanyTimezoneDisplayResolver', () {
    final dubai = CompanyTimezone.tryParse('Asia/Dubai')!;

    test(
      'uses CLDR localized city names while preserving canonical IANA ID',
      () {
        final english = CompanyTimezoneDisplayResolver.resolve(
          dubai,
          const Locale('en'),
        );
        final arabic = CompanyTimezoneDisplayResolver.resolve(
          dubai,
          const Locale('ar'),
        );

        expect(english.value, 'Asia/Dubai');
        expect(arabic.value, 'Asia/Dubai');
        expect(english.localizedName, isNotEmpty);
        expect(arabic.localizedName, contains(RegExp(r'[\u0600-\u06FF]')));
        expect(arabic.displayLabel, contains('Asia/Dubai'));
      },
    );

    test('Egypt and مصر search find canonical Africa/Cairo', () {
      final cairo = CompanyTimezone.tryParse('Africa/Cairo')!;
      final option = CompanyTimezoneDisplayResolver.resolve(
        cairo,
        const Locale('ar'),
      );
      expect(option.value, 'Africa/Cairo');
      expect(option.matches('Egypt'), isTrue);
      expect(option.matches('مصر'), isTrue);
      expect(option.matches('Cairo'), isTrue);
    });

    test('matches Arabic, English, and canonical IANA search terms', () {
      final arabic = CompanyTimezoneDisplayResolver.resolve(
        dubai,
        const Locale('ar'),
      );

      expect(arabic.matches(arabic.localizedName), isTrue);
      expect(arabic.matches(arabic.englishName), isTrue);
      expect(arabic.matches('Asia/Dubai'), isTrue);
      expect(arabic.matches('asia dubai'), isTrue);
      expect(arabic.matches('not-a-timezone'), isFalse);
    });
  });
}
