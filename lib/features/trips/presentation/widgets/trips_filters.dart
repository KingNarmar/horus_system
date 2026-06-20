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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < AppSizes.tabletMaxContentWidth;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TripsSearchField(onChanged: onSearchChanged),
              const SizedBox(height: AppSpacing.md),
              _TripsStatusFilterDropdown(
                statusFilter: statusFilter,
                onChanged: onStatusFilterChanged,
              ),
            ],
          );
        }

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: AppSizes.searchFieldMaxWidth,
              child: _TripsSearchField(onChanged: onSearchChanged),
            ),
            SizedBox(
              width: 280,
              child: _TripsStatusFilterDropdown(
                statusFilter: statusFilter,
                onChanged: onStatusFilterChanged,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TripsSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _TripsSearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(AppIcons.search),
        hintText: l10n.searchTripsHint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _TripsStatusFilterDropdown extends StatelessWidget {
  final TripStatusFilter statusFilter;
  final ValueChanged<TripStatusFilter> onChanged;

  const _TripsStatusFilterDropdown({
    required this.statusFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DropdownButtonFormField<TripStatusFilter>(
      initialValue: statusFilter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.tripStatusHeader,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final filter in TripStatusFilter.values)
          DropdownMenuItem(
            value: filter,
            child: Text(
              l10n.tripStatusFilterLabel(filter),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        onChanged(value);
      },
    );
  }
}
