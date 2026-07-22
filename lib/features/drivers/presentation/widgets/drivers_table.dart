import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/widgets/active_state_confirmation_dialog.dart';
import '../../domain/entities/driver.dart';
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
    final pendingActionDriverId = context.select<DriversCubit, String?>((
      cubit,
    ) {
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
              return DataRow(
                cells: [
                  DataCell(Text(driver.fullName)),
                  DataCell(Text(driver.phone ?? l10n.emptyValue)),
                  DataCell(Text(l10n.driverStatusLabel(driver.status))),
                  DataCell(
                    _DriverActions(
                      driver: driver,
                      canManageDrivers: canManageDrivers,
                      isActionInProgress: pendingActionDriverId == driver.id,
                      onViewDetails: onViewDetails,
                      onEdit: onEdit,
                      onDeactivate: onDeactivate,
                      onReactivate: onReactivate,
                    ),
                  ),
                ],
              );
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
    final active = driver.status.isActive;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.viewDriverDetails,
          onPressed: () => onViewDetails(driver),
          icon: const Icon(AppIcons.view),
        ),
        if (canManageDrivers) ...[
          IconButton(
            tooltip: l10n.editDriverButton,
            onPressed: isActionInProgress ? null : () => onEdit(driver),
            icon: const Icon(AppIcons.edit),
          ),
          IconButton(
            tooltip: active
                ? l10n.deactivateDriverButton
                : l10n.reactivateDriverButton,
            onPressed: isActionInProgress
                ? null
                : () => _handle(context, active),
            icon: _ActionIcon(
              isLoading: isActionInProgress,
              icon: active ? AppIcons.deactivate : AppIcons.reactivate,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handle(BuildContext context, bool active) async {
    final l10n = context.l10n;
    final confirmed = await showActiveStateConfirmationDialog(
      context: context,
      title: active
          ? l10n.driverConfirmDeactivateTitle
          : l10n.driverConfirmReactivateTitle,
      message: active
          ? l10n.driverConfirmDeactivateMessage
          : l10n.driverConfirmReactivateMessage,
      confirmLabel: active
          ? l10n.deactivateDriverButton
          : l10n.reactivateDriverButton,
      cancelLabel: l10n.cancelButton,
    );
    if (!confirmed) return;
    active ? onDeactivate(driver) : onReactivate(driver);
  }
}

class _ActionIcon extends StatelessWidget {
  final bool isLoading;
  final IconData icon;
  const _ActionIcon({required this.isLoading, required this.icon});
  @override
  Widget build(BuildContext context) => isLoading
      ? const SizedBox(
          width: AppSizes.iconMd,
          height: AppSizes.iconMd,
          child: CircularProgressIndicator(
            strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
          ),
        )
      : Icon(icon);
}
