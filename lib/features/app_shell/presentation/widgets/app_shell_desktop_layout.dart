import 'package:flutter/material.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../models/app_shell_destination.dart';
import 'app_shell_body.dart';
import 'app_shell_sidebar_nav.dart';

class AppShellDesktopLayout extends StatelessWidget {
  final CurrentCompanyContext contextData;
  final AppShellDestination selected;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const AppShellDesktopLayout({
    required this.contextData,
    required this.selected,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: AppSizes.desktopSidebarWidth,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'H.O.R.U.S',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(contextData.company.name),
                    Text('Role: ${contextData.role.label}'),
                    const SizedBox(height: AppSpacing.xl),
                    Expanded(
                      child: AppShellSidebarNav(
                        selectedIndex: selectedIndex,
                        onSelect: onSelect,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_outlined),
                      label: const Text('Logout'),
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: AppShellBody(
                contextData: contextData,
                selected: selected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
