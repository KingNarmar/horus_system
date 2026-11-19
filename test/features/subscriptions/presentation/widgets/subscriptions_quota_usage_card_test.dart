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

CompanyQuotaSnapshot _quota({
  int userUsage = 4,
  int userLimit = 3,
  bool unlimitedUsers = false,
}) {
  final entitlement = CompanyEntitlement(
    companyId: 'company-1',
    planCode: 'free_starter',
    policyVersion: 1,
    revision: 1,
    effectiveAt: DateTime.utc(2026, 11, 9),
    status: CompanyEntitlementStatus.active,
    limits: {
      for (final resource in EntitlementResource.values)
        resource: resource == EntitlementResource.companyUsers && unlimitedUsers
            ? const EntitlementLimit.unlimited()
            : EntitlementLimit.finite(
                resource == EntitlementResource.companyUsers ? userLimit : 6,
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
        used: userUsage,
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
            home: Scaffold(
              body: SingleChildScrollView(
                child: SubscriptionsQuotaUsageCard(quota: _quota()),
              ),
            ),
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
          find.text(
            locale.languageCode == 'ar'
                ? 'مستندات الأعمال'
                : 'Business documents',
          ),
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

  for (final (used, limit, message) in [
    (1, 5, 'Within limit'),
    (4, 5, 'Approaching the plan limit'),
    (5, 5, 'Plan limit reached; existing records remain accessible.'),
    (7, 5, 'Above the plan limit; existing records remain accessible.'),
  ]) {
    testWidgets('quota level for $used of $limit is distinct', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SubscriptionsQuotaUsageCard(
                quota: _quota(userUsage: used, userLimit: limit),
              ),
            ),
          ),
        ),
      );
      expect(find.text(message), findsWidgets);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(8));
    });
  }

  testWidgets('unlimited is explicit and has no finite progress bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SubscriptionsQuotaUsageCard(
              quota: _quota(unlimitedUsers: true),
            ),
          ),
        ),
      ),
    );
    expect(find.text('4 of Unlimited used'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(7));
  });
}
