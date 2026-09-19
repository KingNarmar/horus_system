import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/localization/widgets/app_language_toggle_button.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../models/app_shell_destination.dart';
import 'app_shell_content.dart';
import 'app_shell_identity_context.dart';
import 'app_shell_mobile_more_sheet.dart';

class AppShellMobileLayout extends StatelessWidget {
  final CurrentCompanyContext contextData;
  final AuthUser? currentUser;
  final AppShellDestination selected;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const AppShellMobileLayout({
    required this.contextData,
    required this.currentUser,
    required this.selected,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    super.key,
  });

  static const List<AppShellModule> primaryModules = [
    AppShellModule.dashboard,
    AppShellModule.trips,
    AppShellModule.fleet,
    AppShellModule.reports,
  ];

  List<int> get primaryIndexes => primaryModules
      .map(
        (module) => appShellDestinations.indexWhere(
          (destination) => destination.module == module,
        ),
      )
      .toList(growable: false);

  int get navIndex {
    final index = primaryIndexes.indexOf(selectedIndex);
    return index == -1 ? primaryIndexes.length : index;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final indexes = primaryIndexes;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected.label(context)),
            Text(
              contextData.company.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.signedInAsLabel,
            onPressed: () => _showIdentityContext(context),
            icon: const Icon(AppIcons.user),
          ),
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
          if (index == indexes.length) {
            AppShellMobileMoreSheet.show(
              context: context,
              selectedIndex: selectedIndex,
              onSelect: onSelect,
            );
            return;
          }

          onSelect(indexes[index]);
        },
        destinations: [
          for (final index in indexes)
            NavigationDestination(
              icon: Icon(appShellDestinations[index].icon),
              selectedIcon: Icon(appShellDestinations[index].selectedIcon),
              label: appShellDestinations[index].label(context),
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

  Future<void> _showIdentityContext(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppShellIdentityContext(
            user: currentUser,
            contextData: contextData,
          ),
        ),
      ),
    );
  }
}
