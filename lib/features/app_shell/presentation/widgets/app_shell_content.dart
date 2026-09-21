import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/fleet_dependencies.dart';
import '../../../../core/di/routes_dependencies.dart';
import '../../../../core/di/trips_dependencies.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/network/presentation/widgets/network_reconnect_refresh_boundary.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/widgets/auth_user_identity_summary.dart';
import '../../../company/di/company_dependencies.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/policies/company_permission_policy.dart';
import '../../../company/presentation/cubit/company_financial_settings_cubit.dart';
import '../../../company/presentation/cubit/company_timezone_cubit.dart';
import '../../../company/presentation/extensions/company_role_localization.dart';
import '../../../company/presentation/widgets/company_financial_settings_card.dart';
import '../../../company/presentation/widgets/company_timezone_settings_card.dart';
import '../../../customers/presentation/cubit/customers_cubit.dart';
import '../../../customers/presentation/pages/customers_page.dart';
import '../../../dashboard/di/dashboard_dependencies.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../drivers/presentation/cubit/drivers_cubit.dart';
import '../../../drivers/presentation/pages/drivers_page.dart';
import '../../../expense_types/di/expense_types_dependencies.dart';
import '../../../expense_types/domain/policies/expense_types_permission_policy.dart';
import '../../../expense_types/presentation/cubit/expense_types_cubit.dart';
import '../../../expense_types/presentation/pages/expense_types_page.dart';
import '../../../fleet/presentation/cubit/fleet_cubit.dart';
import '../../../fleet/presentation/cubit/fleet_license_documents_cubit.dart';
import '../../../fleet/presentation/pages/fleet_page.dart';
import '../../../payment_methods/di/payment_methods_dependencies.dart';
import '../../../payment_methods/presentation/cubit/payment_methods_cubit.dart';
import '../../../payment_methods/presentation/pages/payment_methods_page.dart';
import '../../../reports/di/reports_dependencies.dart';
import '../../../reports/presentation/cubit/reports_cubit.dart';
import '../../../reports/presentation/pages/reports_page.dart';
import '../../../routes/presentation/cubit/routes_cubit.dart';
import '../../../routes/presentation/pages/routes_page.dart';
import '../../../subscriptions/di/subscriptions_dependencies.dart';
import '../../../subscriptions/presentation/cubit/subscriptions_cubit.dart';
import '../../../subscriptions/presentation/pages/subscriptions_page.dart';
import '../../../trips/presentation/cubit/trips_cubit.dart';
import '../../../trips/presentation/pages/trips_page.dart';
import '../models/app_shell_destination.dart';
import '../models/finance_workspace_section.dart';
import '../pages/finance_workspace_page.dart';
import 'adaptive_access_notice.dart';

class AppShellContent extends StatelessWidget {
  final CurrentCompanyContext contextData;
  final AppShellDestination selected;
  final FinanceWorkspaceSection selectedFinanceSection;
  final ValueChanged<FinanceWorkspaceSection> onFinanceSectionSelected;

  const AppShellContent({
    required this.contextData,
    required this.selected,
    required this.selectedFinanceSection,
    required this.onFinanceSectionSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _ShellContentScrollView(
        padding: AppSpacing.lg,
        maxWidth: AppSizes.mobileMaxContentWidth,
        child: _contentForSelectedModule(),
      ),
      tablet: _ShellContentScrollView(
        padding: AppSpacing.xl,
        maxWidth: AppSizes.tabletMaxContentWidth,
        child: _contentForSelectedModule(),
      ),
      desktop: _ShellContentScrollView(
        padding: AppSpacing.xl,
        maxWidth: AppSizes.desktopMaxContentWidth,
        alignment: Alignment.topLeft,
        child: _contentForSelectedModule(),
      ),
    );
  }

  Widget _contentForSelectedModule() {
    return switch (selected.module) {
      AppShellModule.dashboard => BlocProvider<DashboardCubit>(
        create: (_) => DashboardDependencies.createCubit(),
        child: _ReconnectAware(
          onReconnect: (context) =>
              context.read<DashboardCubit>().load(contextData),
          child: DashboardPage(currentCompanyContext: contextData),
        ),
      ),
      AppShellModule.customers => _ReconnectAware(
        onReconnect: (context) =>
            context.read<CustomersCubit>().loadCustomers(contextData),
        child: CustomersPage(currentCompanyContext: contextData),
      ),
      AppShellModule.drivers => _ReconnectAware(
        onReconnect: (context) =>
            context.read<DriversCubit>().loadDrivers(contextData),
        child: DriversPage(currentCompanyContext: contextData),
      ),
      AppShellModule.fleet => MultiBlocProvider(
        providers: [
          BlocProvider<FleetCubit>(
            create: (_) => FleetDependencies.createFleetCubit(),
          ),
          BlocProvider<FleetLicenseDocumentsCubit>(
            create: (_) => FleetDependencies.createFleetLicenseDocumentsCubit(),
          ),
        ],
        child: _ReconnectAware(
          onReconnect: (context) =>
              context.read<FleetCubit>().loadFleet(contextData),
          child: FleetPage(currentCompanyContext: contextData),
        ),
      ),
      AppShellModule.routes => BlocProvider<RoutesCubit>(
        create: (_) => RoutesDependencies.createRoutesCubit(),
        child: _ReconnectAware(
          onReconnect: (context) =>
              context.read<RoutesCubit>().loadRoutes(contextData),
          child: RoutesPage(currentCompanyContext: contextData),
        ),
      ),
      AppShellModule.trips => BlocProvider<TripsCubit>(
        create: (_) => TripsDependencies.createTripsCubit(),
        child: _ReconnectAware(
          onReconnect: (context) =>
              context.read<TripsCubit>().loadTrips(contextData),
          child: TripsPage(currentCompanyContext: contextData),
        ),
      ),
      AppShellModule.finance => FinanceWorkspacePage(
        currentCompanyContext: contextData,
        selectedSection: selectedFinanceSection,
        onSectionSelected: onFinanceSectionSelected,
      ),
      AppShellModule.reports => BlocProvider<ReportsCubit>(
        create: (_) => ReportsDependencies.createCubit(),
        child: ReportsPage(currentCompanyContext: contextData),
      ),
      AppShellModule.settings => MultiBlocProvider(
        providers: [
          BlocProvider<SubscriptionsCubit>(
            create: (_) => SubscriptionsDependencies.createCubit(),
          ),
          BlocProvider<PaymentMethodsCubit>(
            create: (_) => PaymentMethodsDependencies.createCubit(),
          ),
          BlocProvider<ExpenseTypesCubit>(
            create: (_) => ExpenseTypesDependencies.createCubit(),
          ),
          BlocProvider<CompanyFinancialSettingsCubit>(
            create: (_) => CompanyDependencies.createFinancialSettingsCubit(),
          ),
          BlocProvider<CompanyTimezoneCubit>(
            create: (_) {
              final cubit = CompanyDependencies.createTimezoneCubit();
              if (contextData.canManageCompany) {
                cubit.loadOptions();
              }
              return cubit;
            },
          ),
        ],
        child: _ReconnectAware(
          onReconnect: _refreshSettings,
          child: _SettingsContent(contextData: contextData),
        ),
      ),
    };
  }

  Future<void> _refreshSettings(BuildContext context) async {
    final refreshes = <Future<void>>[
      context.read<SubscriptionsCubit>().load(contextData),
      context.read<PaymentMethodsCubit>().loadPaymentMethods(contextData),
    ];

    if (ExpenseTypesPermissionPolicy.canViewExpenseTypes(contextData.role)) {
      refreshes.add(
        context.read<ExpenseTypesCubit>().loadExpenseTypes(contextData),
      );
    }

    if (contextData.canManageCompany) {
      refreshes.add(context.read<CompanyTimezoneCubit>().loadOptions());
    }

    await Future.wait(refreshes);
  }
}

class _ReconnectAware extends StatelessWidget {
  final Future<void> Function(BuildContext context) onReconnect;
  final Widget child;

  const _ReconnectAware({
    required this.onReconnect,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkReconnectRefreshBoundary(
      onReconnect: () => onReconnect(context),
      child: child,
    );
  }
}

class _ShellContentScrollView extends StatelessWidget {
  final double padding;
  final double maxWidth;
  final AlignmentGeometry alignment;
  final Widget child;

  const _ShellContentScrollView({
    required this.padding,
    required this.maxWidth,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  final CurrentCompanyContext contextData;

  const _SettingsContent({required this.contextData});

  @override
  Widget build(BuildContext context) {
    final canViewExpenseTypes =
        ExpenseTypesPermissionPolicy.canViewExpenseTypes(contextData.role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsCard(contextData: contextData),
        const SizedBox(height: AppSpacing.xl),
        CompanyFinancialSettingsCard(currentCompanyContext: contextData),
        const SizedBox(height: AppSpacing.xl),
        CompanyTimezoneSettingsCard(currentCompanyContext: contextData),
        const SizedBox(height: AppSpacing.xl),
        SubscriptionsPage(currentCompanyContext: contextData),
        const SizedBox(height: AppSpacing.xl),
        PaymentMethodsPage(currentCompanyContext: contextData),
        if (canViewExpenseTypes) ...[
          const SizedBox(height: AppSpacing.xl),
          ExpenseTypesPage(currentCompanyContext: contextData),
        ],
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final CurrentCompanyContext contextData;

  const _SettingsCard({required this.contextData});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final permissions = CompanyPermissionPolicy.permissionsFor(
      contextData.role,
    );
    final authState = context.watch<AuthCubit>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.companySettingsTitle,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthUserIdentitySummary(user: currentUser),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.companyWithName(contextData.company.name)),
            Text(l10n.roleWithName(contextData.role.localizedLabel(context))),
            const SizedBox(height: AppSpacing.xl),
            if (permissions.canViewCompanyUsers)
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.companyUsers),
                icon: const Icon(AppIcons.unavailableModule),
                label: Text(l10n.manageUsers),
              )
            else
              Text(l10n.noPermissionManageUsers),
            const SizedBox(height: AppSpacing.xl),
            const AdaptiveAccessNotice(),
          ],
        ),
      ),
    );
  }
}
