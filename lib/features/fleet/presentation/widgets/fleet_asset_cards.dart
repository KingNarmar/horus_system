import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/tractor_head.dart';
import '../../domain/entities/trailer_entity.dart';
import '../cubit/fleet_cubit.dart';
import '../cubit/fleet_state.dart';
import '../localization/fleet_localizations_x.dart';
import 'fleet_details_dialog.dart';

class TractorHeadCards extends StatelessWidget {
  final List<TractorHead> tractorHeads;
  final bool canManageFleet;
  final bool Function(String id) isActionLoading;
  final ValueChanged<TractorHead> onEdit;
  final ValueChanged<TractorHead> onDeactivate;
  final ValueChanged<TractorHead> onReactivate;

  const TractorHeadCards({required this.tractorHeads, required this.canManageFleet, required this.isActionLoading, required this.onEdit, required this.onDeactivate, required this.onReactivate, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= AppSizes.dataTableBreakpoint) return _TractorHeadsTable(view: this);
      return _FleetCardsLayout(children: tractorHeads.map((item) => _FleetAssetCard(plateNumber: item.plateNumber, status: context.l10n.vehicleStatusText(item.status), isActive: item.isActive, isActionLoading: isActionLoading(item.id), licenseExpiryDate: item.licenseExpiryDate, expectedFuelConsumption: item.expectedFuelConsumption, notes: item.notes, canManageFleet: canManageFleet, onViewDetails: () => _openTractorHeadDetails(context, item), onEdit: () => onEdit(item), onDeactivate: () => onDeactivate(item), onReactivate: () => onReactivate(item))).toList());
    });
  }
}

class TrailerCards extends StatelessWidget {
  final List<TrailerEntity> trailers;
  final bool canManageFleet;
  final bool Function(String id) isActionLoading;
  final ValueChanged<TrailerEntity> onEdit;
  final ValueChanged<TrailerEntity> onDeactivate;
  final ValueChanged<TrailerEntity> onReactivate;

  const TrailerCards({required this.trailers, required this.canManageFleet, required this.isActionLoading, required this.onEdit, required this.onDeactivate, required this.onReactivate, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= AppSizes.dataTableBreakpoint) return _TrailersTable(view: this);
      return _FleetCardsLayout(children: trailers.map((item) => _FleetAssetCard(plateNumber: item.plateNumber, status: context.l10n.vehicleStatusText(item.status), isActive: item.isActive, isActionLoading: isActionLoading(item.id), licenseExpiryDate: item.licenseExpiryDate, notes: item.technicalNotes, canManageFleet: canManageFleet, onViewDetails: () => _openTrailerDetails(context, item), onEdit: () => onEdit(item), onDeactivate: () => onDeactivate(item), onReactivate: () => onReactivate(item))).toList());
    });
  }
}

class _TractorHeadsTable extends StatelessWidget {
  final TractorHeadCards view;
  const _TractorHeadsTable({required this.view});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _TableShell(
      child: DataTable(
        columns: [DataColumn(label: Text(l10n.plateNumberLabel)), DataColumn(label: Text(l10n.vehicleStatusLabel)), DataColumn(label: Text(l10n.vehicleLicenseExpiryDateLabel)), DataColumn(label: Text(l10n.expectedFuelConsumptionLabel)), DataColumn(label: Text(l10n.vehicleNotesLabel)), DataColumn(label: Text(l10n.statusHeader)), DataColumn(label: Text(l10n.actionsHeader))],
        rows: view.tractorHeads.map((item) {
          final loading = view.isActionLoading(item.id);
          return DataRow(cells: [
            DataCell(Text(item.plateNumber)),
            DataCell(Text(l10n.vehicleStatusText(item.status))),
            DataCell(Text(_dateOnlyOrEmpty(context, item.licenseExpiryDate))),
            DataCell(Text(item.expectedFuelConsumption == null ? l10n.emptyValue : _numberText(item.expectedFuelConsumption!))),
            DataCell(Text(item.notes ?? l10n.emptyValue)),
            DataCell(Text(item.isActive ? l10n.activeStatus : l10n.inactiveStatus)),
            DataCell(_Actions(canManage: view.canManageFleet, isActive: item.isActive, isLoading: loading, onViewDetails: () => _openTractorHeadDetails(context, item), onEdit: () => view.onEdit(item), onDeactivate: () => view.onDeactivate(item), onReactivate: () => view.onReactivate(item))),
          ]);
        }).toList(),
      ),
    );
  }
}

class _TrailersTable extends StatelessWidget {
  final TrailerCards view;
  const _TrailersTable({required this.view});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _TableShell(
      child: DataTable(
        columns: [DataColumn(label: Text(l10n.plateNumberLabel)), DataColumn(label: Text(l10n.vehicleStatusLabel)), DataColumn(label: Text(l10n.vehicleLicenseExpiryDateLabel)), DataColumn(label: Text(l10n.technicalNotesLabel)), DataColumn(label: Text(l10n.statusHeader)), DataColumn(label: Text(l10n.actionsHeader))],
        rows: view.trailers.map((item) {
          final loading = view.isActionLoading(item.id);
          return DataRow(cells: [
            DataCell(Text(item.plateNumber)),
            DataCell(Text(l10n.vehicleStatusText(item.status))),
            DataCell(Text(_dateOnlyOrEmpty(context, item.licenseExpiryDate))),
            DataCell(Text(item.technicalNotes ?? l10n.emptyValue)),
            DataCell(Text(item.isActive ? l10n.activeStatus : l10n.inactiveStatus)),
            DataCell(_Actions(canManage: view.canManageFleet, isActive: item.isActive, isLoading: loading, onViewDetails: () => _openTrailerDetails(context, item), onEdit: () => view.onEdit(item), onDeactivate: () => view.onDeactivate(item), onReactivate: () => view.onReactivate(item))),
          ]);
        }).toList(),
      ),
    );
  }
}

class _TableShell extends StatelessWidget {
  final DataTable child;
  const _TableShell({required this.child});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final minWidth = constraints.maxWidth > AppSizes.desktopMinWidth ? constraints.maxWidth : AppSizes.desktopMinWidth;
        return Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: ConstrainedBox(constraints: BoxConstraints(minWidth: minWidth), child: child)));
      });
}

class _FleetCardsLayout extends StatelessWidget {
  final List<Widget> children;
  const _FleetCardsLayout({required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= AppSizes.tabletMaxContentWidth;
        final cardWidth = twoColumns ? (constraints.maxWidth - AppSpacing.md) / 2 : constraints.maxWidth;
        return Padding(padding: const EdgeInsets.only(bottom: AppSpacing.xxxl), child: Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: children.map((child) => SizedBox(width: cardWidth, child: child)).toList()));
      });
}

class _FleetAssetCard extends StatelessWidget {
  final String plateNumber;
  final String status;
  final bool isActive;
  final bool isActionLoading;
  final DateTime? licenseExpiryDate;
  final double? expectedFuelConsumption;
  final String? notes;
  final bool canManageFleet;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;

  const _FleetAssetCard({required this.plateNumber, required this.status, required this.isActive, required this.isActionLoading, required this.licenseExpiryDate, this.expectedFuelConsumption, required this.notes, required this.canManageFleet, required this.onViewDetails, required this.onEdit, required this.onDeactivate, required this.onReactivate});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(plateNumber, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))), Chip(label: Text(status))]),
      const SizedBox(height: AppSpacing.sm),
      _InfoLine(label: l10n.vehicleLicenseExpiryDateLabel, value: _dateOnlyOrEmpty(context, licenseExpiryDate)),
      if (expectedFuelConsumption != null) _InfoLine(label: l10n.expectedFuelConsumptionLabel, value: _numberText(expectedFuelConsumption!)),
      _InfoLine(label: l10n.vehicleNotesLabel, value: notes == null || notes!.isEmpty ? l10n.emptyValue : notes!),
      _InfoLine(label: l10n.statusHeader, value: isActive ? l10n.activeStatus : l10n.inactiveStatus),
      const SizedBox(height: AppSpacing.md),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [OutlinedButton.icon(onPressed: onViewDetails, icon: const Icon(AppIcons.view), label: Text(l10n.fleetDetailsButton)), if (canManageFleet) ...[OutlinedButton.icon(onPressed: isActionLoading ? null : onEdit, icon: const Icon(AppIcons.edit), label: Text(l10n.editButton)), OutlinedButton.icon(onPressed: isActionLoading ? null : (isActive ? onDeactivate : onReactivate), icon: _ActionIcon(isLoading: isActionLoading, icon: isActive ? AppIcons.deactivate : AppIcons.reactivate), label: Text(isActive ? l10n.fleetDeactivateButton : l10n.fleetReactivateButton))]]),
    ])));
  }
}

class _Actions extends StatelessWidget {
  final bool canManage;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;
  const _Actions({required this.canManage, required this.isActive, required this.isLoading, required this.onViewDetails, required this.onEdit, required this.onDeactivate, required this.onReactivate});
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(mainAxisSize: MainAxisSize.min, children: [IconButton(tooltip: l10n.fleetDetailsButton, onPressed: onViewDetails, icon: const Icon(AppIcons.view)), if (canManage) ...[IconButton(tooltip: l10n.editButton, onPressed: isLoading ? null : onEdit, icon: const Icon(AppIcons.edit)), IconButton(tooltip: isActive ? l10n.fleetDeactivateButton : l10n.fleetReactivateButton, onPressed: isLoading ? null : (isActive ? onDeactivate : onReactivate), icon: _ActionIcon(isLoading: isLoading, icon: isActive ? AppIcons.deactivate : AppIcons.reactivate))]]);
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  const _InfoLine({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Wrap(spacing: AppSpacing.sm, children: [Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)), Text(value)]));
}

class _ActionIcon extends StatelessWidget {
  final bool isLoading;
  final IconData icon;
  const _ActionIcon({required this.isLoading, required this.icon});
  @override
  Widget build(BuildContext context) => isLoading ? const SizedBox(width: AppSizes.iconMd, height: AppSizes.iconMd, child: CircularProgressIndicator(strokeWidth: AppSizes.loadingIndicatorStrokeWidth)) : Icon(icon);
}

Future<void> _openTractorHeadDetails(BuildContext context, TractorHead item) async {
  final cubit = context.read<FleetCubit>();
  cubit.loadTractorHeadActivity(item);
  await showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: BlocBuilder<FleetCubit, FleetState>(
        builder: (context, state) => FleetDetailsDialog(assetId: item.id, plateNumber: item.plateNumber, status: item.status, isActive: item.isActive, licenseExpiryDate: item.licenseExpiryDate, expectedFuelConsumption: item.expectedFuelConsumption, notes: item.notes, notesLabel: context.l10n.vehicleNotesLabel, state: state is FleetLoaded ? state : null),
      ),
    ),
  );
  cubit.clearFleetAssetActivity();
}

Future<void> _openTrailerDetails(BuildContext context, TrailerEntity item) async {
  final cubit = context.read<FleetCubit>();
  cubit.loadTrailerActivity(item);
  await showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: BlocBuilder<FleetCubit, FleetState>(
        builder: (context, state) => FleetDetailsDialog(assetId: item.id, plateNumber: item.plateNumber, status: item.status, isActive: item.isActive, licenseExpiryDate: item.licenseExpiryDate, notes: item.technicalNotes, notesLabel: context.l10n.technicalNotesLabel, state: state is FleetLoaded ? state : null),
      ),
    ),
  );
  cubit.clearFleetAssetActivity();
}

String _dateOnlyOrEmpty(BuildContext context, DateTime? value) {
  if (value == null) return context.l10n.emptyValue;
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String _numberText(double value) {
  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}
