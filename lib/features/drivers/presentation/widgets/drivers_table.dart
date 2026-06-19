import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_status.dart';
import '../cubit/drivers_cubit.dart';
import '../cubit/drivers_state.dart';
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
    final pendingActionDriverId = context.select<DriversCubit, String?>((cubit) {
      final state = cubit.state;
      return state is DriversLoaded ? state.pendingActionDriverId : null;
    });

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
                  isActionInProgress: pendingActionDriverId == driver.id,
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
  final bool isActionInProgress;
  final ValueChanged<Driver> onViewDetails;
  final ValueChanged<Driver> onEdit;
  final ValueChanged<Driver> onDeactivate;
  final ValueChanged<Driver> onReactivate;

  const _DriverActions({
    required this.driver,
    required this.canManageDrivers,
    required this.isActionInProgress,
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
          IconButton(tooltip: l10n.editDriverButton, onPressed: isActionInProgress ? null : () => onEdit(driver), icon: const Icon(AppIcons.edit)),
          if (driver.status.isActive)
            IconButton(
              tooltip: l10n.deactivateDriverButton,
              onPressed: isActionInProgress ? null : () => onDeactivate(driver),
              icon: _ActionIcon(isLoading: isActionInProgress, icon: AppIcons.deactivate),
            )
          else
            IconButton(
              tooltip: l10n.reactivateDriverButton,
              onPressed: isActionInProgress ? null : () => onReactivate(driver),
              icon: _ActionIcon(isLoading: isActionInProgress, icon: AppIcons.reactivate),
            ),
        ],
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final bool isLoading;
  final IconData icon;

  const _ActionIcon({required this.isLoading, required this.icon});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return Icon(icon);

    return const SizedBox(
      width: AppSizes.iconMd,
      height: AppSizes.iconMd,
      child: CircularProgressIndicator(
        strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
      ),
    );
  }
}
