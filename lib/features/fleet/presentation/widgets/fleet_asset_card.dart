part of 'fleet_asset_cards.dart';

class _FleetCardsLayout extends StatelessWidget {
  final List<Widget> children;
  const _FleetCardsLayout({required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final twoColumns = constraints.maxWidth >= AppSizes.tabletMaxContentWidth;
      final cardWidth = twoColumns
          ? (constraints.maxWidth - AppSpacing.md) / 2
          : constraints.maxWidth;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: children
              .map((child) => SizedBox(width: cardWidth, child: child))
              .toList(),
        ),
      );
    },
  );
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

  const _FleetAssetCard({
    required this.plateNumber,
    required this.status,
    required this.isActive,
    required this.isActionLoading,
    required this.licenseExpiryDate,
    this.expectedFuelConsumption,
    required this.notes,
    required this.canManageFleet,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    plateNumber,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(label: Text(status)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoLine(
              label: l10n.vehicleLicenseExpiryDateLabel,
              value: _dateOnlyOrEmpty(context, licenseExpiryDate),
            ),
            if (expectedFuelConsumption != null)
              _InfoLine(
                label: l10n.expectedFuelConsumptionLabel,
                value: _numberText(expectedFuelConsumption!),
              ),
            _InfoLine(
              label: l10n.vehicleNotesLabel,
              value: notes == null || notes!.isEmpty ? l10n.emptyValue : notes!,
            ),
            _InfoLine(
              label: l10n.statusHeader,
              value: isActive ? l10n.activeStatus : l10n.inactiveStatus,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(AppIcons.view),
                  label: Text(l10n.fleetDetailsButton),
                ),
                if (canManageFleet) ...[
                  OutlinedButton.icon(
                    onPressed: isActionLoading ? null : onEdit,
                    icon: const Icon(AppIcons.edit),
                    label: Text(l10n.editButton),
                  ),
                  OutlinedButton.icon(
                    onPressed: isActionLoading
                        ? null
                        : (isActive ? onDeactivate : onReactivate),
                    icon: _ActionIcon(
                      isLoading: isActionLoading,
                      icon: isActive
                          ? AppIcons.deactivate
                          : AppIcons.reactivate,
                    ),
                    label: Text(
                      isActive
                          ? l10n.fleetDeactivateButton
                          : l10n.fleetReactivateButton,
                    ),
                  ),
                ],
              ],
            ),
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
  Widget build(BuildContext context) => Padding(
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
