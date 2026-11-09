import 'package:flutter/widgets.dart';
import 'package:horus_system/features/subscriptions/presentation/localization/subscriptions_localizations.dart';
import 'package:test/test.dart';

void main() {
  test('Free Starter uses a dedicated English plan name', () {
    final english = SubscriptionsLocalizations.forLocale(const Locale('en'));
    expect(english.planName('free_starter', 'Untrusted plan name'), 'Free Starter');
  });

  test('Free Starter uses a localized Arabic plan name', () {
    final arabic = SubscriptionsLocalizations.forLocale(const Locale('ar'));
    expect(arabic.planName('free_starter', 'Untrusted plan name'), 'المجانية الأساسية');
  });
}
