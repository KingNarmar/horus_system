import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/driver_settlement_preview.dart';
import '../localization/driver_settlements_localizations.dart';
import 'driver_settlement_calculation_section.dart';
import 'driver_settlement_items_section.dart';

class DriverSettlementPreviewSection extends StatelessWidget {
  final DriverSettlementPreview preview;

  const DriverSettlementPreviewSection({required this.preview, super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.previewTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            DriverSettlementCalculationSection(
              calculation: preview.calculation,
            ),
            const SizedBox(height: AppSpacing.lg),
            DriverSettlementItemsSection(items: preview.items),
          ],
        ),
      ),
    );
  }
}
