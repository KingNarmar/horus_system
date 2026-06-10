import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/policies/company_permission_policy.dart';
import '../../../company/presentation/pages/company_users_page.dart';
import '../models/app_shell_destination.dart';
import '../widgets/adaptive_access_notice.dart';

class AppShellPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const AppShellPage({required this.currentCompanyContext, super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _selectedIndex = 0;

  AppShellDestination get _selected => appShellDestinations[_selectedIndex];

  void _select(int index) => setState(() => _selectedIndex = index);

  void _logout() => context.read<AuthCubit>().logout();

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileShell(
        contextData: widget.currentCompanyContext,
        selected: _selected,
        selectedIndex: _selectedIndex,
        onSelect: _select,
        onLogout: _logout,
      ),
      tablet: _RailShell(
        contextData: widget.currentCompanyContext,
        selected: _selected,
        selectedIndex: _selectedIndex,
        onSelect: _select,
        onLogout: _logout,
      ),
      desktop: _SidebarShell(
        contextData: widget.currentCompanyContext,
        selected: _selected,
        selectedIndex: _selectedIndex,
        onSelect: _select,
        onLogout: _logout,
      ),
    );
  }
}

class _SidebarShell extends StatelessWidget {
  final CurrentCompanyContext contextData;
  final AppShellDestination selected;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _SidebarShell({
    required this.contextData,
    required this.selected,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
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
                    Expanded(child: _SidebarNav(selectedIndex, onSelect)),
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
              child: _ShellBody(contextData: contextData, selected: selected),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailShell extends StatelessWidget {
  final CurrentCompanyContext contextData;
  final AppShellDestination selected;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _RailShell({
    required this.contextData,
    required this.selected,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
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
              child: _ShellBody(contextData: contextData, selected: selected),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  final CurrentCompanyContext contextData;
  final AppShellDestination selected;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _MobileShell({
    required this.contextData,
    required this.selected,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
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
      body: _ShellContent(contextData: contextData, selected: selected),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navIndex,
        onDestinationSelected: (index) {
          if (index == primaryIndexes.length) {
            _showMore(context);
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

  void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: appShellDestinations.length,
          itemBuilder: (context, index) {
            final item = appShellDestinations[index];
            return ListTile(
              selected: index == selectedIndex,
              leading: Icon(index == selectedIndex ? item.selectedIcon : item.icon),
              title: Text(item.label),
              subtitle: Text(item.description),
              onTap: () {
                Navigator.of(context).pop();
                onSelect(index);
              },
            );
          },
        ),
      ),
    );
  }
}

class _SidebarNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _SidebarNav(this.selectedIndex, this.onSelect);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: appShellDestinations.length,
      itemBuilder: (context, index) {
        final item = appShellDestinations[index];
        return ListTile(
          selected: selectedIndex == index,
          leading: Icon(selectedIndex == index ? item.selectedIcon : item.icon),
          title: Text(item.label),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onTap: () => onSelect(index),
        );
      },
    );
  }
}

class _ShellBody extends StatelessWidget {
  final CurrentCompanyContext contextData;
  final AppShellDestination selected;

  const _ShellBody({required this.contextData, required this.selected});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Icon(selected.selectedIcon),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected.label,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(selected.description),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _ShellContent(contextData: contextData, selected: selected)),
      ],
    );
  }
}

class _ShellContent extends StatelessWidget {
  final CurrentCompanyContext contextData;
  final AppShellDestination selected;

  const _ShellContent({required this.contextData, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: selected.module == AppShellModule.settings
          ? _SettingsCard(contextData: contextData)
          : _PlaceholderCard(contextData: contextData, selected: selected),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(selected.selectedIcon, size: AppSizes.iconLg),
            const SizedBox(height: AppSpacing.lg),
            Text(
              selected.label,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(selected.description),
            const SizedBox(height: AppSpacing.md),
            Text('Company: ${contextData.company.name}'),
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
    final permissions = CompanyPermissionPolicy.permissionsFor(contextData.role);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company settings',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Company: ${contextData.company.name}'),
            Text('Role: ${contextData.role.label}'),
            const SizedBox(height: AppSpacing.xl),
            if (permissions.canViewCompanyUsers)
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CompanyUsersPage()),
                ),
                icon: const Icon(Icons.group_outlined),
                label: const Text('Manage users'),
              )
            else
              const Text('You do not have permission to manage users.'),
            const SizedBox(height: AppSpacing.xl),
            const AdaptiveAccessNotice(),
          ],
        ),
      ),
    );
  }
}
