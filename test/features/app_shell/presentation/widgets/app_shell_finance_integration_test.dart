import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/app/routing/app_router.dart';
import 'package:horus_system/app/routing/app_routes.dart';
import 'package:horus_system/features/app_shell/presentation/models/app_shell_destination.dart';
import 'package:horus_system/features/app_shell/presentation/models/finance_workspace_section.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('localizes Finance navigation and preserves Arabic RTL', (
    tester,
  ) async {
    final financeDestination = appShellDestinations.singleWhere(
      (destination) => destination.module == AppShellModule.finance,
    );

    for (final locale in const [Locale('en'), Locale('ar')]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  Text(financeDestination.label(context)),
                  Text(
                    Directionality.of(context) == TextDirection.rtl
                        ? 'rtl'
                        : 'ltr',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      if (locale.languageCode == 'en') {
        expect(find.text('Finance'), findsOneWidget);
        expect(find.text('ltr'), findsOneWidget);
      } else {
        expect(find.text('المالية'), findsOneWidget);
        expect(find.text('rtl'), findsOneWidget);
      }
    }
  });

  group('Finance workspace App Shell integration', () {
    test(
      'registers one canonical Finance destination and preserves deep links',
      () {
        expect(AppRoutes.companyRequiredRoutes, contains(AppRoutes.finance));
        expect(AppRoutes.companyRequiredRoutes, contains(AppRoutes.expenses));
        expect(
          AppRoutes.companyRequiredRoutes,
          contains(AppRoutes.driverSettlements),
        );
        expect(AppRoutes.companyRequiredRoutes, contains(AppRoutes.invoices));
        expect(AppRoutes.companyRequiredRoutes, contains(AppRoutes.payments));
        expect(
          AppRoutes.companyRequiredRoutes,
          contains(AppRoutes.customerStatements),
        );

        final financeDestinations = appShellDestinations
            .where(
              (destination) => destination.module == AppShellModule.finance,
            )
            .toList(growable: false);

        expect(financeDestinations, hasLength(1));
      },
    );

    test('maps legacy finance routes to the correct workspace section', () {
      expect(
        AppRouter.moduleForRoute(AppRoutes.expenses),
        AppShellModule.finance,
      );
      expect(
        AppRouter.financeSectionForRoute(AppRoutes.expenses),
        FinanceWorkspaceSection.companyExpenses,
      );
      expect(
        AppRouter.financeSectionForRoute(AppRoutes.driverSettlements),
        FinanceWorkspaceSection.driverSettlements,
      );
      expect(
        AppRouter.financeSectionForRoute(AppRoutes.invoices),
        FinanceWorkspaceSection.invoices,
      );
      expect(
        AppRouter.financeSectionForRoute(AppRoutes.payments),
        FinanceWorkspaceSection.payments,
      );
      expect(
        AppRouter.financeSectionForRoute(AppRoutes.customerStatements),
        FinanceWorkspaceSection.customerStatements,
      );
      expect(
        AppRouter.financeSectionForRoute(AppRoutes.finance),
        FinanceWorkspaceSection.driverFinance,
      );
    });

    test('hides Finance when the role cannot view any finance section', () {
      final ownerDestinations = appShellDestinationsForRole(CompanyRole.owner);
      final driverDestinations = appShellDestinationsForRole(
        CompanyRole.driver,
      );

      expect(
        ownerDestinations.any(
          (destination) => destination.module == AppShellModule.finance,
        ),
        isTrue,
      );
      expect(
        driverDestinations.any(
          (destination) => destination.module == AppShellModule.finance,
        ),
        isFalse,
      );
    });

    test('uses bounded feature policies for section visibility', () {
      final ownerSections = financeWorkspaceSectionsForRole(CompanyRole.owner);
      final operationsSections = financeWorkspaceSectionsForRole(
        CompanyRole.operations,
      );
      final driverSections = financeWorkspaceSectionsForRole(
        CompanyRole.driver,
      );

      expect(ownerSections, FinanceWorkspaceSection.values);
      expect(
        operationsSections,
        contains(FinanceWorkspaceSection.driverFinance),
      );
      expect(
        operationsSections,
        isNot(contains(FinanceWorkspaceSection.driverSettlements)),
      );
      expect(driverSections, isEmpty);
    });
  });
}
