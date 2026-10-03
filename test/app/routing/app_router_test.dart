import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/app/routing/app_router.dart';
import 'package:horus_system/app/routing/app_routes.dart';
import 'package:horus_system/features/auth/presentation/pages/auth_gate.dart';

void main() {
  testWidgets('login route resolves through the canonical AuthGate', (
    tester,
  ) async {
    Widget? routedPage;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final route = AppRouter.onGenerateRoute(
              const RouteSettings(name: AppRoutes.login),
            );

            routedPage = (route as MaterialPageRoute<void>).builder(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(routedPage, isA<AuthGate>());
  });
}
