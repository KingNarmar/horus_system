import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../driver_settlements/presentation/localization/driver_settlements_localizations.dart';
import '../../../invoices/presentation/localization/invoices_localizations.dart';

enum AppShellModule {
  dashboard,
  customers,
  drivers,
  fleet,
  routes,
  trips,
  expenses,
  driverSettlements,
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
      AppShellModule.driverSettlements =>
        context.driverSettlementsL10n.appShellLabel,
      AppShellModule.invoices => context.invoicesL10n.appShellLabel,
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
      AppShellModule.driverSettlements =>
        context.driverSettlementsL10n.appShellDescription,
      AppShellModule.invoices => context.invoicesL10n.appShellDescription,
      AppShellModule.reports => context.l10n.appShellReportsDescription,
      AppShellModule.settings => context.l10n.appShellSettingsDescription,
    };
  }
}

const List<AppShellDestination> appShellDestinations = [
  AppShellDestination(
    module: AppShellModule.dashboard,
    icon: AppIcons.dashboard,
    selectedIcon: AppIcons.dashboardSelected,
  ),
  AppShellDestination(
    module: AppShellModule.customers,
    icon: AppIcons.customers,
    selectedIcon: AppIcons.customersSelected,
  ),
  AppShellDestination(
    module: AppShellModule.drivers,
    icon: AppIcons.drivers,
    selectedIcon: AppIcons.driversSelected,
  ),
  AppShellDestination(
    module: AppShellModule.fleet,
    icon: AppIcons.fleet,
    selectedIcon: AppIcons.fleetSelected,
  ),
  AppShellDestination(
    module: AppShellModule.routes,
    icon: AppIcons.routes,
    selectedIcon: AppIcons.routesSelected,
  ),
  AppShellDestination(
    module: AppShellModule.trips,
    icon: AppIcons.trips,
    selectedIcon: AppIcons.tripsSelected,
  ),
  AppShellDestination(
    module: AppShellModule.expenses,
    icon: AppIcons.expenses,
    selectedIcon: AppIcons.expensesSelected,
  ),
  AppShellDestination(
    module: AppShellModule.driverSettlements,
    icon: AppIcons.driverSettlements,
    selectedIcon: AppIcons.driverSettlementsSelected,
  ),
  AppShellDestination(
    module: AppShellModule.invoices,
    icon: AppIcons.invoices,
    selectedIcon: AppIcons.invoicesSelected,
  ),
  AppShellDestination(
    module: AppShellModule.reports,
    icon: AppIcons.reports,
    selectedIcon: AppIcons.reportsSelected,
  ),
  AppShellDestination(
    module: AppShellModule.settings,
    icon: AppIcons.settings,
    selectedIcon: AppIcons.settingsSelected,
  ),
];
