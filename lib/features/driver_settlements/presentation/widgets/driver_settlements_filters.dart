import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/driver_settlement_driver_option.dart';
import '../../domain/entities/driver_settlement_status.dart';
import '../localization/driver_settlement_localizations_x.dart';
import '../localization/driver_settlements_localizations.dart';

class DriverSettlementsFilters extends StatelessWidget {
  final List<DriverSettlementDriverOption> drivers;
  final String? selectedDriverId;
  final DriverSettlementStatus? selectedStatus;
  final bool includeVoided;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onDriverChanged;
  final ValueChanged<DriverSettlementStatus?> onStatusChanged;
  final ValueChanged<bool> onIncludeVoidedChanged;

  const DriverSettlementsFilters({
    required this.drivers,
    required this.selectedDriverId,
    required this.selectedStatus,
    required this.includeVoided,
    required this.onSearchChanged,
    required this.onDriverChanged,
    required this.onStatusChanged,
    required this.onIncludeVoidedChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final useFullWidth =
            constraints.maxWidth < AppSizes.dataTableBreakpoint;
        final searchWidth = useFullWidth
            ? constraints.maxWidth
            : AppSizes.searchFieldMaxWidth;
        final driverWidth = useFullWidth
            ? constraints.maxWidth
            : AppSizes.minButtonWidth * 1.8;
        final statusWidth = useFullWidth
            ? constraints.maxWidth
            : AppSizes.minButtonWidth * 1.6;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: searchWidth,
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(AppIcons.search),
                  hintText: strings.searchHint,
                ),
              ),
            ),
            SizedBox(
              width: driverWidth,
              child: DropdownButtonFormField<String?>(
                initialValue: selectedDriverId,
                isExpanded: true,
                decoration: InputDecoration(labelText: strings.driverLabel),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(strings.allDrivers),
                  ),
                  ...drivers.map(
                    (driver) => DropdownMenuItem<String?>(
                      value: driver.id,
                      child: Text(
                        driver.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: onDriverChanged,
              ),
            ),
            SizedBox(
              width: statusWidth,
              child: DropdownButtonFormField<DriverSettlementStatus?>(
                initialValue: selectedStatus,
                isExpanded: true,
                decoration: InputDecoration(labelText: strings.status),
                items: [
                  DropdownMenuItem<DriverSettlementStatus?>(
                    value: null,
                    child: Text(strings.allStatuses),
                  ),
                  ...DriverSettlementStatus.values.map(
                    (status) => DropdownMenuItem<DriverSettlementStatus?>(
                      value: status,
                      child: Text(context.driverSettlementStatusLabel(status)),
                    ),
                  ),
                ],
                onChanged: onStatusChanged,
              ),
            ),
            FilterChip(
              selected: includeVoided,
              label: Text(strings.showVoided),
              onSelected: onIncludeVoidedChanged,
            ),
          ],
        );
      },
    );
  }
}
