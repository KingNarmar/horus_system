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
import '../../../../core/responsive/responsive_layout.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/policies/company_permission_policy.dart';
import '../../../company/presentation/extensions/company_role_localization.dart';
import '../../../company_expenses/di/company_expenses_dependencies.dart';
import '../../../company_expenses/presentation/cubit/company_expenses_cubit.dart';
import '../../../company_expenses/presentation/pages/company_expenses_page.dart';
import '../../../customers/presentation/pages/customers_page.dart';
import '../../../driver_settlements/di/driver_settlements_dependencies.dart';
import '../../../driver_settlements/presentation/cubit/driver_settlements_cubit.dart';
import '../../../driver_settlements/presentation/pages/driver_settlements_page.dart';
import '../../../drivers/presentation/pages/drivers_page.dart';
import '../../../fleet/presentation/cubit/fleet_cubit.dart';
import '../../../fleet/presentation/pages/fleet_page.dart';
import '../../../invoices/di/invoices_dependencies.dart';
import '../../../invoices/presentation/cubit/invoices_cubit.dart';
import '../../../invoices/presentation/pages/invoices_page.dart';
import '../../../payment_methods/di/payment_methods_dependencies.dart';
import '../../../payment_methods/presentation/cubit/payment_methods_cubit.dart';
import '../../../payment_methods/presentation/pages/payment_methods_page.dart';
import '../../../routes/presentation/cubit/routes_cubit.dart';
import '../../../routes/presentation/pages/routes_page.dart';
import '../../../trips/presentation/cubit/trips_cubit.dart';
import '../../../trips/presentation/pages/trips_page.dart';
import '../models/app_shell_destination.dart';
import 'adaptive_access_notice.dart';

class AppShellContent extends StatelessWidget {
  final CurrentCompanyContext contextData;
  final AppShellDestination selected;

  const AppShellContent({
    required this.contextData,
    required this.selected,
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
      AppShellModule.customers => CustomersPage(
        currentCompanyContext: contextData,
      ),
      AppShellModule.drivers => DriversPage(currentCompanyContext: contextData),
      AppShellModule.fleet => BlocProvider<FleetCubit>(
        create: (_) => FleetDependencies.createFleetCubit(),
        child: FleetPage(currentCompanyContext: contextData),
      ),
      AppShellModule.routes => BlocProvider<RoutesCubit>(
        create: (_) => RoutesDependencies.createRoutesCubit(),
        child: RoutesPage(currentCompanyContext: contextData),
      ),
      AppShellModule.trips => BlocProvider<TripsCubit>(
        create: (_) => TripsDependencies.createTripsCubit(),
        child: TripsPage(currentCompanyContext: contextData),
      ),
      AppShellModule.expenses => BlocProvider<CompanyExpensesCubit>(
        create: (_) => CompanyExpensesDependencies.createCubit(),
        child: CompanyExpensesPage(currentCompanyContext: contextData),
      ),
      AppShellModule.driverSettlements => BlocProvider<DriverSettlementsCubit>(
        create: (_) => DriverSettlementsDependencies.createCubit(),
        child: DriverSettlementsPage(currentCompanyContext: contextData),
      ),
      AppShellModule.invoices => BlocProvider<InvoicesCubit>(
        create: (_) => InvoicesDependencies.createInvoicesCubit(),
        child: InvoicesPage(currentCompanyContext: contextData),
      ),
      AppShellModule.settings => BlocProvider<PaymentMethodsCubit>(
        create: (_) => PaymentMethodsDependencies.createCubit(),
        child: _SettingsContent(contextData: contextData),
      ),
      _ => _PlaceholderCard(contextData: contextData, selected: selected),
    };
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

class _PlaceholderCard extends StatelessWidget {
  final CurrentCompanyContext contextData;
  final AppShellDestination selected;

  const _PlaceholderCard({required this.contextData, required this.selected});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(selected.selectedIcon, size: AppSizes.iconLg),
            const SizedBox(height: AppSpacing.lg),
            Text(
              selected.label(context),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(selected.description(context)),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.companyWithName(contextData.company.name)),
            const SizedBox(height: AppSpacing.xl),
            const AdaptiveAccessNotice(),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsCard(contextData: contextData),
        const SizedBox(height: AppSpacing.xl),
        PaymentMethodsPage(currentCompanyContext: contextData),
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
