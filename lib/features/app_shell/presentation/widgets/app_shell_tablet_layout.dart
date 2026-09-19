import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/localization/widgets/app_language_toggle_button.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../models/app_shell_destination.dart';
import '../models/finance_workspace_section.dart';
import 'app_shell_body.dart';

class AppShellTabletLayout extends StatelessWidget {
  final CurrentCompanyContext contextData;
  final AuthUser? currentUser;
  final List<AppShellDestination> destinations;
  final AppShellDestination selected;
  final int selectedIndex;
  final FinanceWorkspaceSection selectedFinanceSection;
  final ValueChanged<int> onSelect;
  final ValueChanged<FinanceWorkspaceSection> onFinanceSectionSelected;
  final VoidCallback onLogout;

  const AppShellTabletLayout({
    required this.contextData,
    required this.currentUser,
    required this.destinations,
    required this.selected,
    required this.selectedIndex,
    required this.selectedFinanceSection,
    required this.onSelect,
    required this.onFinanceSectionSelected,
    required this.onLogout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: AppLanguageToggleButton.compact(),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: IconButton(
                    tooltip: l10n.logout,
                    onPressed: onLogout,
                    icon: const Icon(AppIcons.logout),
                  ),
                ),
              ),
              destinations: destinations
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label(context)),
                    ),
                  )
                  .toList(growable: false),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: AppShellBody(
                contextData: contextData,
                currentUser: currentUser,
                selected: selected,
                selectedFinanceSection: selectedFinanceSection,
                onFinanceSectionSelected: onFinanceSectionSelected,
                showIdentityContext: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
