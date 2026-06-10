import 'package:flutter/material.dart';

import '../../features/app_shell/presentation/models/app_shell_destination.dart';
import '../../features/app_shell/presentation/pages/app_shell_page.dart';
import '../../features/auth/presentation/pages/auth_gate.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/company/presentation/pages/company_onboarding_page.dart';
import '../../features/company/presentation/pages/company_users_page.dart';
import 'app_route_guards.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => _pageFor(settings.name ?? AppRoutes.root),
    );
  }

  static Widget _pageFor(String routeName) {
    return switch (routeName) {
      AppRoutes.root => const AuthGate(),
      AppRoutes.login => const LoginPage(),
      AppRoutes.register => const RegisterPage(),
      AppRoutes.companyOnboarding => const AuthenticatedRouteGuard(
          child: CompanyOnboardingPage(),
        ),
      AppRoutes.companyUsers => CompanyRequiredRouteGuard(
          builder: (_) => const CompanyUsersPage(),
        ),
      _ when AppRoutes.companyRequiredRoutes.contains(routeName) =>
        CompanyRequiredRouteGuard(
          builder: (currentCompanyContext) => AppShellPage(
            currentCompanyContext: currentCompanyContext,
            initialModule: _moduleForRoute(routeName),
          ),
        ),
      _ => const AuthGate(),
    };
  }

  static AppShellModule _moduleForRoute(String routeName) {
    return switch (routeName) {
      AppRoutes.customers => AppShellModule.customers,
      AppRoutes.drivers => AppShellModule.drivers,
      AppRoutes.fleet => AppShellModule.fleet,
      AppRoutes.routes => AppShellModule.routes,
      AppRoutes.trips => AppShellModule.trips,
      AppRoutes.expenses => AppShellModule.expenses,
      AppRoutes.invoices => AppShellModule.invoices,
      AppRoutes.reports => AppShellModule.reports,
      AppRoutes.settings => AppShellModule.settings,
      _ => AppShellModule.dashboard,
    };
  }
}
