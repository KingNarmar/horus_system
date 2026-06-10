import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(selected.label),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_outlined),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Fleet',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
