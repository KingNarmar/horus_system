import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_status_filter.dart';
import '../localization/trips_localizations_x.dart';

class TripsFilters extends StatelessWidget {
  final TripStatusFilter statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<TripStatusFilter> onStatusFilterChanged;

  const TripsFilters({
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Wrap(
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
              hintText: l10n.searchTripsHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        SegmentedButton<TripStatusFilter>(
          segments: [
            for (final filter in TripStatusFilter.values)
              ButtonSegment(
                value: filter,
                label: Text(l10n.tripStatusFilterLabel(filter)),
              ),
          ],
          selected: {statusFilter},
          onSelectionChanged: (selected) {
            onStatusFilterChanged(selected.first);
          },
        ),
      ],
    );
  }
}
