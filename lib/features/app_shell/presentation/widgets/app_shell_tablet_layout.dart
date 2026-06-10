import 'package:flutter/material.dart';

import '../../../company/domain/entities/current_company_context.dart';
import '../models/app_shell_destination.dart';
import 'app_shell_body.dart';

class AppShellTabletLayout extends StatelessWidget {
  final CurrentCompanyContext contextData;
  final AppShellDestination selected;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const AppShellTabletLayout({
    required this.contextData,
    required this.selected,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: IconButton(
                    tooltip: 'Logout',
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_outlined),
                  ),
                ),
              ),
              destinations: appShellDestinations
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
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
