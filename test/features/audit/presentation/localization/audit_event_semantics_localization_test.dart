import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/audit/presentation/localization/audit_display_localizations_x.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('shows correct English semantic labels', (tester) async {
    final labels = await _labels(tester, const Locale('en'));
    expect(labels, [
      'Accepted', 'Cancelled', 'Issued', 'Payment status changed',
      'Registered', 'Resent', 'Revoked', 'Sent', 'Voided',
      'Not available',
    ]);
  });

  testWidgets('shows correct Arabic semantic labels', (tester) async {
    final labels = await _labels(tester, const Locale('ar'));
    expect(labels, [
      'تم القبول', 'تم الإلغاء', 'تم الإصدار', 'تم تغيير حالة الدفع',
      'تم التسجيل', 'تمت إعادة الإرسال', 'تم سحب الدعوة',
      'تم الإرسال', 'تم الإبطال', 'غير متاح',
    ]);
  });
}

Future<List<String>> _labels(WidgetTester tester, Locale locale) async {
  late List<String> result;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          result = [
            for (final action in [
              'accepted', 'cancelled', 'issued', 'payment_status_changed',
              'registered', 'resent', 'revoked', 'sent', 'voided',
              'unknown_future_action',
            ]) l10n.auditActionValueDisplayLabel(action),
          ];
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pump();
  return result;
}
