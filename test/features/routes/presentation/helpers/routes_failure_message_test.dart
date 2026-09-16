import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/routes/presentation/helpers/routes_failure_message.dart';
import 'package:horus_system/features/routes/presentation/localization/routes_localizations_x.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  group('PC-07 Route presentation hardening', () {
    test('labels the persisted default price field as a per-ton rate', () {
      final en = AppLocalizationsEn();
      final ar = AppLocalizationsAr();

      expect(
        en.routeAuditFieldLabel('default_freight_price'),
        'Default freight price / t',
      );
      expect(
        ar.routeAuditFieldLabel('default_freight_price'),
        'سعر النقل الافتراضي / طن',
      );
    });

    testWidgets('localizes invalid Route freight rate failures', (
      tester,
    ) async {
      const failure = ValidationFailure(
        code: FailureCodes.validationRouteFreightRateInvalid,
        message: 'raw domain message',
      );

      expect(
        await _messageFor(tester, const Locale('en'), failure),
        'Enter a valid non-negative number.',
      );
      expect(
        await _messageFor(tester, const Locale('ar'), failure),
        'أدخل رقم صحيح غير سالب.',
      );
    });

    testWidgets('localizes missing company financial configuration', (
      tester,
    ) async {
      const failure = ConflictFailure(
        code: CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
        message: 'raw domain message',
      );

      expect(
        await _messageFor(tester, const Locale('en'), failure),
        'Configure the company financial settings before using this module.',
      );
      expect(
        await _messageFor(tester, const Locale('ar'), failure),
        'أكمل الإعدادات المالية للشركة قبل استخدام هذه الوحدة.',
      );
    });
  });
}

Future<String> _messageFor(
  WidgetTester tester,
  Locale locale,
  Failure failure,
) async {
  String? message;

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          message = routesFailureMessage(context, failure);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  return message!;
}
