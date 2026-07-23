import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/adaptive_detail_row.dart';
import '../../domain/entities/driver_settlement_item.dart';
import '../helpers/driver_settlement_formatters.dart';
import '../localization/driver_settlement_localizations_x.dart';
import '../localization/driver_settlements_localizations.dart';

class DriverSettlementItemsSection extends StatelessWidget {
  final List<DriverSettlementItem> items;
  final bool showTitle;

  const DriverSettlementItemsSection({
    required this.items,
    this.showTitle = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text(
            strings.sourceItems,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (items.isEmpty)
          Text(strings.noSourceItems)
        else
          ...items.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdaptiveDetailRow(
                      label: context.driverSettlementItemLabel(item),
                      value: formatDriverSettlementAmount(
                        item.amount,
                        localeName,
                      ),
                      valueStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      context.driverSettlementItemDirectionLabel(
                        item.direction,
                      ),
                    ),
                    if (item.sourceDate != null)
                      Text(
                        formatDriverSettlementDate(
                          item.sourceDate!,
                          localeName,
                        ),
                      ),
                    if (item.descriptionKey != null &&
                        item.descriptionKey!.trim().isNotEmpty)
                      Text(item.descriptionKey!.trim()),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
