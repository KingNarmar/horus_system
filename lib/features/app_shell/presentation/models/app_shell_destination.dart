import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_extension.dart';

enum AppShellModule {
  dashboard,
  customers,
  drivers,
  fleet,
  routes,
  trips,
  expenses,
  invoices,
  reports,
  settings,
}

class AppShellDestination {
  final AppShellModule module;
  final IconData icon;
  final IconData selectedIcon;

  const AppShellDestination({
    required this.module,
    required this.icon,
    required this.selectedIcon,
  });

  String label(BuildContext context) {
    return switch (module) {
      AppShellModule.dashboard => context.l10n.appShellDashboardLabel,
      AppShellModule.customers => context.l10n.appShellCustomersLabel,
      AppShellModule.drivers => context.l10n.appShellDriversLabel,
      AppShellModule.fleet => context.l10n.appShellFleetLabel,
      AppShellModule.routes => context.l10n.appShellRoutesLabel,
      AppShellModule.trips => context.l10n.appShellTripsLabel,
      AppShellModule.expenses => context.l10n.appShellExpensesLabel,
      AppShellModule.invoices => context.l10n.appShellInvoicesLabel,
      AppShellModule.reports => context.l10n.appShellReportsLabel,
      AppShellModule.settings => context.l10n.appShellSettingsLabel,
    };
  }

  String description(BuildContext context) {
    return switch (module) {
      AppShellModule.dashboard => context.l10n.appShellDashboardDescription,
      AppShellModule.customers => context.l10n.appShellCustomersDescription,
      AppShellModule.drivers => context.l10n.appShellDriversDescription,
      AppShellModule.fleet => context.l10n.appShellFleetDescription,
      AppShellModule.routes => context.l10n.appShellRoutesDescription,
      AppShellModule.trips => context.l10n.appShellTripsDescription,
      AppShellModule.expenses => context.l10n.appShellExpensesDescription,
      AppShellModule.invoices => context.l10n.appShellInvoicesDescription,
      AppShellModule.reports => context.l10n.appShellReportsDescription,
      AppShellModule.settings => context.l10n.appShellSettingsDescription,
    };
  }
}

const List<AppShellDestination> appShellDestinations = [
  AppShellDestination(
    module: AppShellModule.dashboard,
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  AppShellDestination(
    module: AppShellModule.customers,
    icon: Icons.apartment_outlined,
    selectedIcon: Icons.apartment,
  ),
  AppShellDestination(
    module: AppShellModule.drivers,
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge,
  ),
  AppShellDestination(
    module: AppShellModule.fleet,
    icon: Icons.local_shipping_outlined,
    selectedIcon: Icons.local_shipping,
  ),
  AppShellDestination(
    module: AppShellModule.routes,
    icon: Icons.alt_route_outlined,
    selectedIcon: Icons.alt_route,
  ),
  AppShellDestination(
    module: AppShellModule.trips,
    icon: Icons.route_outlined,
    selectedIcon: Icons.route,
  ),
  AppShellDestination(
    module: AppShellModule.expenses,
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
  ),
  AppShellDestination(
    module: AppShellModule.invoices,
    icon: Icons.request_quote_outlined,
    selectedIcon: Icons.request_quote,
  ),
  AppShellDestination(
    module: AppShellModule.reports,
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
  ),
  AppShellDestination(
    module: AppShellModule.settings,
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];
