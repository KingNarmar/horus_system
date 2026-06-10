import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/policies/company_permission_policy.dart';
import '../../../company/presentation/extensions/company_role_localization.dart';
import '../../../company/presentation/pages/company_users_page.dart';
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
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CompanyUsersPage(),
                  ),
                ),
                icon: const Icon(Icons.group_outlined),
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
