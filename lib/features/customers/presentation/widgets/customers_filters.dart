import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/customer_status_filter.dart';

class CustomersFilters extends StatelessWidget {
  final CustomerStatusFilter statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CustomerStatusFilter> onStatusFilterChanged;

  const CustomersFilters({
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
          constraints: const BoxConstraints(maxWidth: AppSizes.searchFieldMaxWidth),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(AppIcons.search),
              hintText: l10n.searchCustomersHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        SegmentedButton<CustomerStatusFilter>(
          segments: [
            ButtonSegment(value: CustomerStatusFilter.all, label: Text(l10n.customersStatusAllFilter)),
            ButtonSegment(value: CustomerStatusFilter.active, label: Text(l10n.customersStatusActiveFilter)),
            ButtonSegment(value: CustomerStatusFilter.inactive, label: Text(l10n.customersStatusInactiveFilter)),
          ],
          selected: {statusFilter},
          onSelectionChanged: (selected) => onStatusFilterChanged(selected.first),
        ),
      ],
    );
  }
}
