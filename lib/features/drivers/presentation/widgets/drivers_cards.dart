import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/widgets/active_state_confirmation_dialog.dart';
import '../../domain/entities/driver.dart';
import '../cubit/drivers_cubit.dart';
import '../cubit/drivers_state.dart';
import '../localization/drivers_localizations_x.dart';

class DriversCards extends StatelessWidget {
  final List<Driver> drivers;
  final bool canManageDrivers;
  final ValueChanged<Driver> onViewDetails;
  final ValueChanged<Driver> onEdit;
  final ValueChanged<Driver> onDeactivate;
  final ValueChanged<Driver> onReactivate;

  const DriversCards({required this.drivers, required this.canManageDrivers, required this.onViewDetails, required this.onEdit, required this.onDeactivate, required this.onReactivate, super.key});

  @override
  Widget build(BuildContext context) {
    final pendingActionDriverId = context.select<DriversCubit, String?>((cubit) {
      final state = cubit.state;
      return state is DriversLoaded ? state.pendingActionDriverId : null;
    });
    return Column(children: drivers.map((driver) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: _DriverCard(driver: driver, canManageDrivers: canManageDrivers, isActionInProgress: pendingActionDriverId == driver.id, onViewDetails: onViewDetails, onEdit: onEdit, onDeactivate: onDeactivate, onReactivate: onReactivate))).toList());
  }
}

class _DriverCard extends StatelessWidget {
  final Driver driver;
  final bool canManageDrivers;
  final bool isActionInProgress;
  final ValueChanged<Driver> onViewDetails;
  final ValueChanged<Driver> onEdit;
  final ValueChanged<Driver> onDeactivate;
  final ValueChanged<Driver> onReactivate;

  const _DriverCard({required this.driver, required this.canManageDrivers, required this.isActionInProgress, required this.onViewDetails, required this.onEdit, required this.onDeactivate, required this.onReactivate});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = driver.status.isActive;
    return Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(driver.fullName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: AppSpacing.sm),
      if (driver.phone != null) Text(l10n.phoneLine(driver.phone!)),
      Text(l10n.statusLine(l10n.driverStatusLabel(driver.status))),
      const SizedBox(height: AppSpacing.md),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [OutlinedButton.icon(onPressed: () => onViewDetails(driver), icon: const Icon(AppIcons.view), label: Text(l10n.viewDriverDetails)), if (canManageDrivers) ...[OutlinedButton.icon(onPressed: isActionInProgress ? null : () => onEdit(driver), icon: const Icon(AppIcons.edit), label: Text(l10n.editDriverButton)), OutlinedButton.icon(onPressed: isActionInProgress ? null : () => _handle(context, active), icon: _ActionIcon(isLoading: isActionInProgress, icon: active ? AppIcons.deactivate : AppIcons.reactivate), label: Text(active ? l10n.deactivateDriverButton : l10n.reactivateDriverButton))]]),
    ])));
  }

  Future<void> _handle(BuildContext context, bool active) async {
    final l10n = context.l10n;
    final confirmed = await showActiveStateConfirmationDialog(context: context, title: active ? l10n.driverConfirmDeactivateTitle : l10n.driverConfirmReactivateTitle, message: active ? l10n.driverConfirmDeactivateMessage : l10n.driverConfirmReactivateMessage, confirmLabel: active ? l10n.deactivateDriverButton : l10n.reactivateDriverButton, cancelLabel: l10n.cancelButton);
    if (!confirmed) return;
    active ? onDeactivate(driver) : onReactivate(driver);
  }
}

class _ActionIcon extends StatelessWidget {
  final bool isLoading;
  final IconData icon;
  const _ActionIcon({required this.isLoading, required this.icon});
  @override
  Widget build(BuildContext context) => isLoading ? const SizedBox(width: AppSizes.iconMd, height: AppSizes.iconMd, child: CircularProgressIndicator(strokeWidth: AppSizes.loadingIndicatorStrokeWidth)) : Icon(icon);
}
