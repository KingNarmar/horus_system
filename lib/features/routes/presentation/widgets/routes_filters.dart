import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/route_status_filter.dart';

class RoutesFilters extends StatelessWidget {
  final RouteStatusFilter statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<RouteStatusFilter> onStatusFilterChanged;

  const RoutesFilters({
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
              hintText: l10n.searchRoutesHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        SegmentedButton<RouteStatusFilter>(
          segments: [
            ButtonSegment(
              value: RouteStatusFilter.all,
              label: Text(l10n.routesStatusAllFilter),
            ),
            ButtonSegment(
              value: RouteStatusFilter.active,
              label: Text(l10n.routesStatusActiveFilter),
            ),
            ButtonSegment(
              value: RouteStatusFilter.inactive,
              label: Text(l10n.routesStatusInactiveFilter),
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
