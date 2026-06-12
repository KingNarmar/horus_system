import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/driver.dart';
import '../localization/drivers_localizations_x.dart';

class DriversCards extends StatelessWidget {
  final List<Driver> drivers;
  final bool canManageDrivers;
  final ValueChanged<Driver> onViewDetails;
  final ValueChanged<Driver> onEdit;
  final ValueChanged<Driver> onDeactivate;
  final ValueChanged<Driver> onReactivate;

  const DriversCards({
    required this.drivers,
    required this.canManageDrivers,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: drivers.map((driver) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _DriverCard(
            driver: driver,
            canManageDrivers: canManageDrivers,
            onViewDetails: onViewDetails,
            onEdit: onEdit,
            onDeactivate: onDeactivate,
            onReactivate: onReactivate,
          ),
        );
      }).toList(),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final Driver driver;
  final bool canManageDrivers;
  final ValueChanged<Driver> onViewDetails;
  final ValueChanged<Driver> onEdit;
  final ValueChanged<Driver> onDeactivate;
  final ValueChanged<Driver> onReactivate;

  const _DriverCard({
    required this.driver,
    required this.canManageDrivers,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(driver.fullName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            if (driver.phone != null) Text(l10n.phoneLine(driver.phone!)),
            Text(l10n.statusLine(driver.isActive ? l10n.activeStatus : l10n.inactiveStatus)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(onPressed: () => onViewDetails(driver), icon: const Icon(AppIcons.view), label: Text(l10n.viewDriverDetails)),
                if (canManageDrivers) ...[
                  OutlinedButton.icon(onPressed: () => onEdit(driver), icon: const Icon(AppIcons.edit), label: Text(l10n.editDriverButton)),
                  if (driver.isActive)
                    OutlinedButton.icon(onPressed: () => onDeactivate(driver), icon: const Icon(AppIcons.deactivate), label: Text(l10n.deactivateDriverButton))
                  else
                    OutlinedButton.icon(onPressed: () => onReactivate(driver), icon: const Icon(AppIcons.reactivate), label: Text(l10n.reactivateDriverButton)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
