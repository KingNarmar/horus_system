import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/app_dependencies.dart';
import '../../features/app_shell/presentation/models/app_shell_destination.dart';
import '../../features/app_shell/presentation/models/finance_workspace_section.dart';
import '../../features/app_shell/presentation/pages/app_shell_page.dart';
import '../../features/auth/presentation/cubit/account_deletion_cubit.dart';
import '../../features/auth/presentation/cubit/password_recovery_cubit.dart';
import '../../features/auth/presentation/pages/account_deletion_page.dart';
import '../../features/auth/presentation/pages/auth_gate.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/company/di/company_dependencies.dart';
import '../../features/company/presentation/cubit/company_timezone_cubit.dart';
import '../../features/company/presentation/pages/company_creation_page.dart';
import '../../features/company/presentation/pages/company_invitation_acceptance_page.dart';
import '../../features/company/presentation/pages/company_users_page.dart';
import 'app_route_guards.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeUri = Uri.tryParse(settings.name ?? AppRoutes.root);
    final routeName = _routePath(routeUri);
    final invitationToken = routeUri?.queryParameters['token'];

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) =>
          _pageFor(routeName, invitationToken: invitationToken),
    );
  }

  static String _routePath(Uri? routeUri) {
    final path = routeUri?.path.trim();
    return path == null || path.isEmpty ? AppRoutes.root : path;
  }

  static Widget _pageFor(String routeName, {String? invitationToken}) {
    return switch (routeName) {
      AppRoutes.root || AppRoutes.login => const AuthGate(),
      AppRoutes.register => const RegisterPage(),
      AppRoutes.forgotPassword => BlocProvider<PasswordRecoveryCubit>(
        create: (_) => AppDependencies.createPasswordRecoveryCubit(),
        child: const ForgotPasswordPage(),
      ),
      AppRoutes.companyInvitation => CompanyInvitationAcceptancePage(
        initialToken: invitationToken,
      ),
      AppRoutes.accountDeletion => AuthenticatedRouteGuard(
        child: BlocProvider<AccountDeletionCubit>(
          create: (_) => AppDependencies.createAccountDeletionCubit(),
          child: const AccountDeletionPage(),
        ),
      ),
      AppRoutes.companyCreation => AuthenticatedRouteGuard(
        child: BlocProvider<CompanyTimezoneCubit>(
          create: (_) =>
              CompanyDependencies.createTimezoneCubit()..loadOptions(),
          child: const CompanyCreationPage(),
        ),
      ),
      AppRoutes.companyUsers => CompanyRequiredRouteGuard(
        builder: (_) => const CompanyUsersPage(),
      ),
      _ when AppRoutes.companyRequiredRoutes.contains(routeName) =>
        CompanyRequiredRouteGuard(
          builder: (currentCompanyContext) => AppShellPage(
            currentCompanyContext: currentCompanyContext,
            initialModule: moduleForRoute(routeName),
            initialFinanceSection: financeSectionForRoute(routeName),
          ),
        ),
      _ => const AuthGate(),
    };
  }

  static AppShellModule moduleForRoute(String routeName) {
    return switch (routeName) {
      AppRoutes.customers => AppShellModule.customers,
      AppRoutes.drivers => AppShellModule.drivers,
      AppRoutes.fleet => AppShellModule.fleet,
      AppRoutes.routes => AppShellModule.routes,
      AppRoutes.trips => AppShellModule.trips,
      AppRoutes.finance ||
      AppRoutes.expenses ||
      AppRoutes.driverSettlements ||
      AppRoutes.invoices ||
      AppRoutes.payments ||
      AppRoutes.customerStatements => AppShellModule.finance,
      AppRoutes.reports => AppShellModule.reports,
      AppRoutes.settings => AppShellModule.settings,
      _ => AppShellModule.dashboard,
    };
  }

  static FinanceWorkspaceSection financeSectionForRoute(String routeName) {
    return switch (routeName) {
      AppRoutes.driverSettlements => FinanceWorkspaceSection.driverSettlements,
      AppRoutes.expenses => FinanceWorkspaceSection.companyExpenses,
      AppRoutes.invoices => FinanceWorkspaceSection.invoices,
      AppRoutes.payments => FinanceWorkspaceSection.payments,
      AppRoutes.customerStatements =>
        FinanceWorkspaceSection.customerStatements,
      _ => FinanceWorkspaceSection.driverFinance,
    };
  }
}
