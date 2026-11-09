import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/subscriptions/domain/entities/company_entitlement.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_feature.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_limit.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_resource.dart';
import 'package:horus_system/features/subscriptions/presentation/widgets/subscriptions_current_plan_card.dart';

void main() {
  for (final (locale, planName, noExpiration) in [
    (const Locale('en'), 'Free Starter', 'No expiration'),
    (const Locale('ar'), 'المجانية الأساسية', 'بدون تاريخ انتهاء'),
  ]) {
    testWidgets('renders canonical Starter grant in ${locale.languageCode}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: SubscriptionsCurrentPlanCard(entitlement: _grant()),
          ),
        ),
      );

      expect(find.text(planName), findsOneWidget);
      expect(find.text(noExpiration), findsOneWidget);
    });
  }
}

CompanyEntitlement _grant() => CompanyEntitlement(
  companyId: 'company-1',
  planCode: 'free_starter',
  policyVersion: 1,
  revision: 1,
  effectiveAt: DateTime.utc(2026, 11, 9),
  status: CompanyEntitlementStatus.active,
  limits: {
    for (final resource in EntitlementResource.values)
      resource: EntitlementLimit.finite(1),
  },
  enabledFeatures: const {EntitlementFeature.invoicePdf},
);
