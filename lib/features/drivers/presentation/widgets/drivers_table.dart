import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_status.dart';
import '../localization/drivers_localizations_x.dart';

class DriversTable extends StatelessWidget {
  final List<Driver> drivers;
  final bool canManageDrivers;
  final ValueChanged<Driver> onViewDetails;
  final ValueChanged<Driver> onEdit;
  final ValueChanged<Driver> onDeactivate;
  final ValueChanged<Driver> onReactivate;

  const DriversTable({
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
    final l10n = context.l10n;
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: AppSizes.desktopMinWidth),
          child: DataTable(
            columns: [
              DataColumn(label: Text(l10n.driverNameLabel)),
              DataColumn(label: Text(l10n.phoneLabel)),
              DataColumn(label: Text(l10n.statusHeader)),
              DataColumn(label: Text(l10n.actionsHeader)),
            ],
            rows: drivers.map((driver) {
              return DataRow(cells: [
                DataCell(Text(driver.fullName)),
                DataCell(Text(driver.phone ?? l10n.emptyValue)),
                DataCell(Text(l10n.driverStatusLabel(driver.status))),
                DataCell(_DriverActions(
                  driver: driver,
                  canManageDrivers: canManageDrivers,
                  onViewDetails: onViewDetails,
                  onEdit: onEdit,
                  onDeactivate: onDeactivate,
                  onReactivate: onReactivate,
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _DriverActions extends StatelessWidget {
  final Driver driver;
  final bool canManageDrivers;
  final ValueChanged<Driver> onViewDetails;
  final ValueChanged<Driver> onEdit;
  final ValueChanged<Driver> onDeactivate;
  final ValueChanged<Driver> onReactivate;

  const _DriverActions({
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(tooltip: l10n.viewDriverDetails, onPressed: () => onViewDetails(driver), icon: const Icon(AppIcons.view)),
        if (canManageDrivers) ...[
          IconButton(tooltip: l10n.editDriverButton, onPressed: () => onEdit(driver), icon: const Icon(AppIcons.edit)),
          if (driver.status.isActive)
            IconButton(tooltip: l10n.deactivateDriverButton, onPressed: () => onDeactivate(driver), icon: const Icon(AppIcons.deactivate))
          else
            IconButton(tooltip: l10n.reactivateDriverButton, onPressed: () => onReactivate(driver), icon: const Icon(AppIcons.reactivate)),
        ],
      ],
    );
  }
}
