import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/app/routing/app_route_guards.dart';
import 'package:horus_system/app/routing/app_router.dart';
import 'package:horus_system/app/routing/app_routes.dart';
import 'package:horus_system/features/app_shell/presentation/models/app_shell_destination.dart';
import 'package:horus_system/features/app_shell/presentation/pages/app_shell_page.dart';
import 'package:horus_system/features/auth/presentation/pages/auth_gate.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';

void main() {
  group('AppRouter startup routes', () {
    testWidgets('keeps default startup on the guarded root flow', (tester) async {
      final page = await _startupPage(tester, AppRoutes.root);

      expect(page, isA<AuthGate>());
    });

    test('uses a valid direct route as the only startup route', () {
      final routes = AppRouter.onGenerateInitialRoutes(
        AppRoutes.driverSettlements,
      );

      expect(routes, hasLength(1));
      expect(routes.single.settings.name, AppRoutes.driverSettlements);
    });

    testWidgets(
      'keeps driver settlements startup company guarded and resolves its module',
      (tester) async {
        final page = await _startupPage(tester, AppRoutes.driverSettlements);

        expect(page, isA<CompanyRequiredRouteGuard>());

        final guard = page as CompanyRequiredRouteGuard;
        final guardedPage = guard.builder(_currentCompanyContext);

        expect(guardedPage, isA<AppShellPage>());
        expect(
          (guardedPage as AppShellPage).initialModule,
          AppShellModule.driverSettlements,
        );
      },
    );

    test('falls back to root for an unknown startup route', () {
      final routes = AppRouter.onGenerateInitialRoutes('/unknown');

      expect(routes, hasLength(1));
      expect(routes.single.settings.name, AppRoutes.root);
    });
  });
}

const _currentCompanyContext = CurrentCompanyContext(
  company: Company(id: 'company-1', name: 'Horus Transport'),
  role: CompanyRole.owner,
);

Future<Widget> _startupPage(
  WidgetTester tester,
  String startupRouteName,
) async {
  const hostKey = ValueKey('route-test-host');
  await tester.pumpWidget(
    const MaterialApp(home: SizedBox(key: hostKey)),
  );

  final routes = AppRouter.onGenerateInitialRoutes(startupRouteName);
  expect(routes, hasLength(1));

  final route = routes.single;
  expect(route, isA<MaterialPageRoute<void>>());

  final materialRoute = route as MaterialPageRoute<void>;
  final context = tester.element(find.byKey(hostKey));
  return materialRoute.builder(context);
}
