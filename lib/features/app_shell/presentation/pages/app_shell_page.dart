import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/presentation/cubit/company_switcher_cubit.dart';
import '../../../company/presentation/widgets/company_switcher_panel.dart';
import '../models/app_shell_destination.dart';
import '../models/finance_workspace_section.dart';
import '../widgets/app_shell_desktop_layout.dart';
import '../widgets/company_realtime_session_boundary.dart';
import '../widgets/app_shell_mobile_layout.dart';
import '../widgets/app_shell_tablet_layout.dart';

class AppShellPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;
  final AppShellModule initialModule;
  final FinanceWorkspaceSection initialFinanceSection;

  const AppShellPage({
    required this.currentCompanyContext,
    this.initialModule = AppShellModule.dashboard,
    this.initialFinanceSection = FinanceWorkspaceSection.driverFinance,
    super.key,
  });

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  late AppShellModule _selectedModule;
  late FinanceWorkspaceSection _selectedFinanceSection;

  List<AppShellDestination> get _destinations =>
      appShellDestinationsForRole(widget.currentCompanyContext.role);

  int get _selectedIndex {
    final index = _destinations.indexWhere(
      (destination) => destination.module == _selectedModule,
    );
    return index == -1 ? 0 : index;
  }

  AppShellDestination get _selected => _destinations[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _selectedModule = _resolveInitialModule(widget.initialModule);
    _selectedFinanceSection = _resolveInitialFinanceSection(
      widget.initialFinanceSection,
    );
  }

  @override
  void didUpdateWidget(covariant AppShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final destinations = _destinations;
    if (!destinations.any(
      (destination) => destination.module == _selectedModule,
    )) {
      _selectedModule = destinations.first.module;
    }
    _selectedFinanceSection = _resolveInitialFinanceSection(
      _selectedFinanceSection,
    );
  }

  void _select(int index) {
    final destinations = _destinations;
    if (index < 0 || index >= destinations.length) return;
    setState(() => _selectedModule = destinations[index].module);
  }

  void _selectFinanceSection(FinanceWorkspaceSection section) {
    if (!section.canView(widget.currentCompanyContext.role)) return;
    setState(() => _selectedFinanceSection = section);
  }

  void _openCompanySwitcher() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider<CompanySwitcherCubit>(
        create: (_) => AppDependencies.createCompanySwitcherCubit()..load(),
        child: BlocListener<AuthCubit, AuthState>(
          listener: (_, state) {
            if (state is! AuthAuthenticated && sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SingleChildScrollView(
                child: CompanySwitcherPanel(
                  activeCompanyId: widget.currentCompanyContext.companyId,
                  onSwitchSucceeded: () {
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  onJoin: () {
                    Navigator.of(sheetContext).pop();
                    if (mounted) {
                      Navigator.of(context).pushNamed(
                        AppRoutes.companyInvitation,
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _logout() => context.read<AuthCubit>().logout();

  AppShellModule _resolveInitialModule(AppShellModule module) {
    final destinations = _destinations;
    if (destinations.any((destination) => destination.module == module)) {
      return module;
    }
    return destinations.first.module;
  }

  FinanceWorkspaceSection _resolveInitialFinanceSection(
    FinanceWorkspaceSection preferred,
  ) {
    return resolveFinanceWorkspaceSection(
          role: widget.currentCompanyContext.role,
          preferred: preferred,
        ) ??
        FinanceWorkspaceSection.driverFinance;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final destinations = _destinations;

    return CompanyRealtimeSessionBoundary(
      companyId: widget.currentCompanyContext.companyId,
      role: widget.currentCompanyContext.role,
      userId: currentUser?.id,
      child: ResponsiveLayout(
        mobile: AppShellMobileLayout(
          contextData: widget.currentCompanyContext,
          currentUser: currentUser,
          destinations: destinations,
          selected: _selected,
          selectedIndex: _selectedIndex,
          selectedFinanceSection: _selectedFinanceSection,
          onSelect: _select,
          onFinanceSectionSelected: _selectFinanceSection,
          onLogout: _logout,
          onSwitchCompany: _openCompanySwitcher,
        ),
        tablet: AppShellTabletLayout(
          contextData: widget.currentCompanyContext,
          currentUser: currentUser,
          destinations: destinations,
          selected: _selected,
          selectedIndex: _selectedIndex,
          selectedFinanceSection: _selectedFinanceSection,
          onSelect: _select,
          onFinanceSectionSelected: _selectFinanceSection,
          onLogout: _logout,
          onSwitchCompany: _openCompanySwitcher,
        ),
        desktop: AppShellDesktopLayout(
          contextData: widget.currentCompanyContext,
          currentUser: currentUser,
          destinations: destinations,
          selected: _selected,
          selectedIndex: _selectedIndex,
          selectedFinanceSection: _selectedFinanceSection,
          onSelect: _select,
          onFinanceSectionSelected: _selectFinanceSection,
          onLogout: _logout,
          onSwitchCompany: _openCompanySwitcher,
        ),
      ),
    );
  }
}
