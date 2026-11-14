import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:horus_system/features/subscriptions/domain/entities/company_entitlement.dart';
import 'package:horus_system/features/subscriptions/domain/entities/company_quota_snapshot.dart';
import 'package:horus_system/features/subscriptions/domain/entities/company_quota_usage.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_feature.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_limit.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_resource.dart';
import 'package:horus_system/features/subscriptions/presentation/widgets/subscriptions_quota_usage_card.dart';

CompanyQuotaSnapshot _quota() {
  final entitlement = CompanyEntitlement(
    companyId: 'company-1',
    planCode: 'free_starter',
    policyVersion: 1,
    revision: 1,
    effectiveAt: DateTime.utc(2026, 11, 9),
    status: CompanyEntitlementStatus.active,
    limits: {
      for (final resource in EntitlementResource.values)
        resource: EntitlementLimit.finite(
          resource == EntitlementResource.companyUsers ? 3 : 6,
        ),
    },
    enabledFeatures: const {EntitlementFeature.invoicePdf},
  );
  return CompanyQuotaSnapshot(
    entitlement: entitlement,
    usage: {
      EntitlementResource.companyUsers: CompanyQuotaUsage(
        resource: EntitlementResource.companyUsers,
        limit: entitlement.limitFor(EntitlementResource.companyUsers),
        used: 4,
      ),
      EntitlementResource.combinedVehicles: CompanyQuotaUsage(
        resource: EntitlementResource.combinedVehicles,
        limit: entitlement.limitFor(EntitlementResource.combinedVehicles),
        used: 2,
      ),
      for (final resource in [
        EntitlementResource.customers,
        EntitlementResource.drivers,
        EntitlementResource.routes,
        EntitlementResource.lifetimeTrips,
        EntitlementResource.lifetimeInvoices,
        EntitlementResource.businessDocuments,
      ])
        resource: CompanyQuotaUsage(
          resource: resource,
          limit: entitlement.limitFor(resource),
          used: resource == EntitlementResource.drivers ? 7 : 1,
        ),
    },
  );
}

void main() {
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets(
      'usage shows counts and over-cap note for ${locale.languageCode}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: Scaffold(body: SubscriptionsQuotaUsageCard(quota: _quota())),
          ),
        );
        expect(
          find.text(
            locale.languageCode == 'ar' ? 'المستخدم 4 من 3' : '4 of 3 used',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            locale.languageCode == 'ar' ? 'المستخدم 2 من 6' : '2 of 6 used',
          ),
          findsOneWidget,
        );
        expect(
          find.text(locale.languageCode == 'ar' ? 'العملاء' : 'Customers'),
          findsOneWidget,
        );
        expect(
          find.text(locale.languageCode == 'ar' ? 'السائقون' : 'Drivers'),
          findsOneWidget,
        );
        expect(
          find.text(locale.languageCode == 'ar' ? 'المسارات' : 'Routes'),
          findsOneWidget,
        );
        expect(
          find.text(locale.languageCode == 'ar' ? 'مستندات الأعمال' : 'Business documents'),
          findsOneWidget,
        );
        expect(
          find.text(
            locale.languageCode == 'ar'
                ? 'تجاوز تاريخي للحد؛ تظل السجلات الحالية متاحة.'
                : 'Above the plan limit; existing records remain accessible.',
          ),
          findsNWidgets(2),
        );
      },
    );
  }
}
