import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/fleet_dependencies.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/policies/company_permission_policy.dart';
import '../../../company/presentation/extensions/company_role_localization.dart';
import '../../../customers/presentation/pages/customers_page.dart';
import '../../../drivers/presentation/pages/drivers_page.dart';
import '../../../fleet/presentation/cubit/fleet_cubit.dart';
import '../../../fleet/presentation/pages/fleet_page.dart';
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
      AppShellModule.customers => CustomersPage(currentCompanyContext: contextData),
      AppShellModule.drivers => DriversPage(currentCompanyContext: contextData),
      AppShellModule.fleet => BlocProvider<FleetCubit>(
          create: (_) => FleetDependencies.createFleetCubit(),
          child: FleetPage(currentCompanyContext: contextData),
        ),
      AppShellModule.settings => _SettingsCard(contextData: contextData),
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
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.companyUsers),
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
