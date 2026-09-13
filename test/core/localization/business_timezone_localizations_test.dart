import 'package:flutter/widgets.dart';
import 'package:horus_system/core/localization/business_timezone_localizations.dart';
import 'package:test/test.dart';

void main() {
  test('provides focused English business timezone readiness copy', () {
    final strings = BusinessTimezoneLocalizations.forLocale(
      const Locale('en'),
    );

    expect(
      strings.configurationRequired,
      'Configure the company business timezone before using this module.',
    );
    expect(strings.configurationRequired.toLowerCase(), contains('timezone'));
    expect(strings.configurationRequired.toLowerCase(), isNot(contains('currency')));
  });

  test('provides focused Arabic business timezone readiness copy', () {
    final strings = BusinessTimezoneLocalizations.forLocale(
      const Locale('ar'),
    );

    expect(
      strings.configurationRequired,
      'اضبط المنطقة الزمنية للعمل بالشركة قبل استخدام هذه الوحدة.',
    );
    expect(strings.configurationRequired, contains('المنطقة الزمنية'));
    expect(strings.configurationRequired, isNot(contains('عملة')));
  });
}
