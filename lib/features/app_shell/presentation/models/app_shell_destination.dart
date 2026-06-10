import 'package:flutter/material.dart';

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
  final String label;
  final String description;
  final IconData icon;
  final IconData selectedIcon;

  const AppShellDestination({
    required this.module,
    required this.label,
    required this.description,
    required this.icon,
    required this.selectedIcon,
  });
}

const List<AppShellDestination> appShellDestinations = [
  AppShellDestination(
    module: AppShellModule.dashboard,
    label: 'Dashboard',
    description: 'Live overview for company operations and finance.',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  AppShellDestination(
    module: AppShellModule.customers,
    label: 'Customers',
    description: 'Manage customer master data and account activity.',
    icon: Icons.apartment_outlined,
    selectedIcon: Icons.apartment,
  ),
  AppShellDestination(
    module: AppShellModule.drivers,
    label: 'Drivers',
    description: 'Manage drivers, status, and driver actions.',
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge,
  ),
  AppShellDestination(
    module: AppShellModule.fleet,
    label: 'Fleet',
    description: 'Manage tractor heads, trailers, and availability.',
    icon: Icons.local_shipping_outlined,
    selectedIcon: Icons.local_shipping,
  ),
  AppShellDestination(
    module: AppShellModule.routes,
    label: 'Routes',
    description: 'Manage loading points, delivery points, and lanes.',
    icon: Icons.alt_route_outlined,
    selectedIcon: Icons.alt_route,
  ),
  AppShellDestination(
    module: AppShellModule.trips,
    label: 'Trips',
    description: 'Create, track, and update trips.',
    icon: Icons.route_outlined,
    selectedIcon: Icons.route,
  ),
  AppShellDestination(
    module: AppShellModule.expenses,
    label: 'Expenses',
    description: 'Track trip costs, fees, and financial movements.',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
  ),
  AppShellDestination(
    module: AppShellModule.invoices,
    label: 'Invoices',
    description: 'Create invoices, register payments, and track balances.',
    icon: Icons.request_quote_outlined,
    selectedIcon: Icons.request_quote,
  ),
  AppShellDestination(
    module: AppShellModule.reports,
    label: 'Reports',
    description: 'Review operational and financial reports.',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
  ),
  AppShellDestination(
    module: AppShellModule.settings,
    label: 'Settings',
    description: 'Manage company settings, users, roles, and access.',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];
