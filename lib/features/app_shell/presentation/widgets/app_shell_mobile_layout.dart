import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/localization/widgets/app_language_toggle_button.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../models/app_shell_destination.dart';
import 'app_shell_content.dart';
import 'app_shell_mobile_more_sheet.dart';

class AppShellMobileLayout extends StatelessWidget {
  final CurrentCompanyContext contextData;
  final AppShellDestination selected;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const AppShellMobileLayout({
    required this.contextData,
    required this.selected,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    super.key,
  });

  static const List<int> primaryIndexes = [0, 5, 3, 8];

  int get navIndex {
    final index = primaryIndexes.indexOf(selectedIndex);
    return index == -1 ? primaryIndexes.length : index;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(selected.label(context)),
        actions: [
          const AppLanguageToggleButton.compact(),
          IconButton(
            tooltip: l10n.logout,
            onPressed: onLogout,
            icon: const Icon(AppIcons.logout),
          ),
        ],
      ),
      body: AppShellContent(contextData: contextData, selected: selected),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navIndex,
        onDestinationSelected: (index) {
          if (index == primaryIndexes.length) {
            AppShellMobileMoreSheet.show(
              context: context,
              selectedIndex: selectedIndex,
              onSelect: onSelect,
            );
            return;
          }

          onSelect(primaryIndexes[index]);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(AppIcons.dashboard),
            selectedIcon: const Icon(AppIcons.dashboardSelected),
            label: appShellDestinations[0].label(context),
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.trips),
            selectedIcon: const Icon(AppIcons.tripsSelected),
            label: appShellDestinations[5].label(context),
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.fleet),
            selectedIcon: const Icon(AppIcons.fleetSelected),
            label: appShellDestinations[3].label(context),
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.reports),
            selectedIcon: const Icon(AppIcons.reportsSelected),
            label: appShellDestinations[8].label(context),
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.appsOutlined),
            selectedIcon: const Icon(AppIcons.apps),
            label: l10n.appShellMoreLabel,
          ),
        ],
      ),
    );
  }
}
