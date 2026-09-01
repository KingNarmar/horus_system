import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/app/routing/app_routes.dart';
import 'package:horus_system/features/company/presentation/pages/company_entry_page.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('offers create company and invitation entry paths', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    expect(find.text('Create company'), findsOneWidget);
    expect(find.text('Company invitation'), findsOneWidget);
  });

  testWidgets('create company action opens company creation route', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    await tester.tap(find.text('Create company'));
    await tester.pumpAndSettle();

    expect(find.text('creation-route'), findsOneWidget);
  });

  testWidgets('invitation action opens invitation route', (tester) async {
    await tester.pumpWidget(_testApp());

    await tester.tap(find.text('Company invitation'));
    await tester.pumpAndSettle();

    expect(find.text('invitation-route'), findsOneWidget);
  });

  testWidgets('Arabic locale renders entry choices RTL', (tester) async {
    await tester.pumpWidget(_testApp(locale: const Locale('ar')));

    final createCompany = find.text('إنشاء شركة');
    expect(createCompany, findsOneWidget);
    expect(Directionality.of(tester.element(createCompany)), TextDirection.rtl);
  });
}

Widget _testApp({Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routes: {
      AppRoutes.companyCreation: (_) =>
          const Scaffold(body: Text('creation-route')),
      AppRoutes.companyInvitation: (_) =>
          const Scaffold(body: Text('invitation-route')),
    },
    home: const CompanyEntryPage(),
  );
}
