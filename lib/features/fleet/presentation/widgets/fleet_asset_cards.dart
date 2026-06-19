import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/tractor_head.dart';
import '../../domain/entities/trailer_entity.dart';
import '../localization/fleet_localizations_x.dart';

class TractorHeadCards extends StatelessWidget {
  final List<TractorHead> tractorHeads;
  final bool canManageFleet;
  final bool Function(String id) isActionLoading;
  final ValueChanged<TractorHead> onEdit;
  final ValueChanged<TractorHead> onDeactivate;
  final ValueChanged<TractorHead> onReactivate;

  const TractorHeadCards({
    required this.tractorHeads,
    required this.canManageFleet,
    required this.isActionLoading,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tractorHeads
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _FleetAssetCard(
                plateNumber: item.plateNumber,
                status: context.l10n.vehicleStatusText(item.status),
                isActive: item.isActive,
                isActionLoading: isActionLoading(item.id),
                licenseExpiryDate: item.licenseExpiryDate,
                notes: item.notes,
                canManageFleet: canManageFleet,
                onEdit: () => onEdit(item),
                onDeactivate: () => onDeactivate(item),
                onReactivate: () => onReactivate(item),
              ),
            ),
          )
          .toList(),
    );
  }
}

class TrailerCards extends StatelessWidget {
  final List<TrailerEntity> trailers;
  final bool canManageFleet;
  final bool Function(String id) isActionLoading;
  final ValueChanged<TrailerEntity> onEdit;
  final ValueChanged<TrailerEntity> onDeactivate;
  final ValueChanged<TrailerEntity> onReactivate;

  const TrailerCards({
    required this.trailers,
    required this.canManageFleet,
    required this.isActionLoading,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: trailers
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _FleetAssetCard(
                plateNumber: item.plateNumber,
                status: context.l10n.vehicleStatusText(item.status),
                isActive: item.isActive,
                isActionLoading: isActionLoading(item.id),
                licenseExpiryDate: item.licenseExpiryDate,
                notes: item.technicalNotes,
                canManageFleet: canManageFleet,
                onEdit: () => onEdit(item),
                onDeactivate: () => onDeactivate(item),
                onReactivate: () => onReactivate(item),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FleetAssetCard extends StatelessWidget {
  final String plateNumber;
  final String status;
  final bool isActive;
  final bool isActionLoading;
  final DateTime? licenseExpiryDate;
  final String? notes;
  final bool canManageFleet;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;

  const _FleetAssetCard({
    required this.plateNumber,
    required this.status,
    required this.isActive,
    required this.isActionLoading,
    required this.licenseExpiryDate,
    required this.notes,
    required this.canManageFleet,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    plateNumber,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(label: Text(status)),
                if (canManageFleet) ...[
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: l10n.editButton,
                    onPressed: isActionLoading ? null : onEdit,
                    icon: const Icon(AppIcons.edit),
                  ),
                  IconButton(
                    tooltip: isActive ? l10n.fleetDeactivateButton : l10n.fleetReactivateButton,
                    onPressed: isActionLoading ? null : (isActive ? onDeactivate : onReactivate),
                    icon: isActionLoading
                        ? const SizedBox(
                            width: AppSizes.iconSm,
                            height: AppSizes.iconSm,
                            child: CircularProgressIndicator(strokeWidth: AppSizes.loadingIndicatorStrokeWidth),
                          )
                        : Icon(isActive ? AppIcons.deactivate : AppIcons.reactivate),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoLine(label: l10n.vehicleLicenseExpiryDateLabel, value: licenseExpiryDate == null ? l10n.emptyValue : _dateOnly(licenseExpiryDate!)),
            _InfoLine(label: l10n.vehicleNotesLabel, value: notes == null || notes!.isEmpty ? l10n.emptyValue : notes!),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.sm,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}

String _dateOnly(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
