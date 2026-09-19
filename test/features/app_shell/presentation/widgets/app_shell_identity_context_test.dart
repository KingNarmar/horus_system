import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/app_shell/presentation/widgets/app_shell_identity_context.dart';
import 'package:horus_system/features/auth/domain/entities/auth_user.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('shows signed-in user, active company, and localized role', (
    tester,
  ) async {
    await tester.pumpWidget(_app(user: _user));

    expect(find.text('Signed in as'), findsOneWidget);
    expect(find.text('Mina Adly'), findsOneWidget);
    expect(find.text('mina@example.com'), findsOneWidget);
    expect(find.text('Company: Horus Transport'), findsOneWidget);
    expect(find.text('Role: Owner'), findsOneWidget);
  });

  testWidgets('uses semantic identity fallback without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(user: const AuthUser(id: 'user-without-profile')),
    );

    expect(find.text('Unknown User'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic context renders RTL with localized role', (tester) async {
    await tester.pumpWidget(_app(user: _user, locale: const Locale('ar')));

    final role = find.text('الدور: المالك');
    expect(role, findsOneWidget);
    expect(Directionality.of(tester.element(role)), TextDirection.rtl);
  });
}

Widget _app({required AuthUser user, Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        width: 320,
        child: AppShellIdentityContext(
          user: user,
          contextData: _context,
        ),
      ),
    ),
  );
}

const _user = AuthUser(
  id: 'user-1',
  email: 'mina@example.com',
  fullName: 'Mina Adly',
);

const _context = CurrentCompanyContext(
  company: Company(id: 'company-1', name: 'Horus Transport'),
  role: CompanyRole.owner,
);
