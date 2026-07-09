import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/vehicle_status_filter.dart';
import '../cubit/fleet_state.dart';

class FleetFilters extends StatelessWidget {
  final FleetAssetTab selectedTab;
  final VehicleStatusFilter statusFilter;
  final ValueChanged<FleetAssetTab> onTabChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<VehicleStatusFilter> onStatusFilterChanged;

  const FleetFilters({
    required this.selectedTab,
    required this.statusFilter,
    required this.onTabChanged,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<FleetAssetTab>(
          segments: [
            ButtonSegment(
              value: FleetAssetTab.tractorHeads,
              label: Text(l10n.tractorHeadsTab),
              icon: const Icon(AppIcons.fleet),
            ),
            ButtonSegment(
              value: FleetAssetTab.trailers,
              label: Text(l10n.trailersTab),
              icon: const Icon(AppIcons.fleetSelected),
            ),
          ],
          selected: {selectedTab},
          onSelectionChanged: (selected) => onTabChanged(selected.first),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.searchFieldMaxWidth,
              ),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(AppIcons.search),
                  hintText: l10n.searchFleetHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            SegmentedButton<VehicleStatusFilter>(
              segments: [
                ButtonSegment(
                  value: VehicleStatusFilter.all,
                  label: Text(l10n.fleetStatusAllFilter),
                ),
                ButtonSegment(
                  value: VehicleStatusFilter.active,
                  label: Text(l10n.fleetStatusActiveFilter),
                ),
                ButtonSegment(
                  value: VehicleStatusFilter.inactive,
                  label: Text(l10n.fleetStatusInactiveFilter),
                ),
              ],
              selected: {statusFilter},
              onSelectionChanged: (selected) =>
                  onStatusFilterChanged(selected.first),
            ),
          ],
        ),
      ],
    );
  }
}
