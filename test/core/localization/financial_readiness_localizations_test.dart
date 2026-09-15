import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/localization/financial_readiness_localizations.dart';

void main() {
  test('uses financial-only readiness guidance in English and Arabic', () {
    final english = FinancialReadinessLocalizations.forLocale(
      const Locale('en'),
    );
    final arabic = FinancialReadinessLocalizations.forLocale(
      const Locale('ar'),
    );

    expect(
      english.configurationRequired,
      'Configure the company financial settings before using this module.',
    );
    expect(
      arabic.configurationRequired,
      'أكمل الإعدادات المالية للشركة قبل استخدام هذه الوحدة.',
    );
    expect(english.configurationRequired, isNot(contains('timezone')));
    expect(arabic.configurationRequired, isNot(contains('المنطقة الزمنية')));
  });
}
