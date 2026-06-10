import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/responsive/responsive_layout.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../models/app_shell_destination.dart';
import '../widgets/app_shell_desktop_layout.dart';
import '../widgets/app_shell_mobile_layout.dart';
import '../widgets/app_shell_tablet_layout.dart';

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
      mobile: AppShellMobileLayout(
        contextData: widget.currentCompanyContext,
        selected: _selected,
        selectedIndex: _selectedIndex,
        onSelect: _select,
        onLogout: _logout,
      ),
      tablet: AppShellTabletLayout(
        contextData: widget.currentCompanyContext,
        selected: _selected,
        selectedIndex: _selectedIndex,
        onSelect: _select,
        onLogout: _logout,
      ),
      desktop: AppShellDesktopLayout(
        contextData: widget.currentCompanyContext,
        selected: _selected,
        selectedIndex: _selectedIndex,
        onSelect: _select,
        onLogout: _logout,
      ),
    );
  }
}
