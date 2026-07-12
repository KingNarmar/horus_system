import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/driver_settlement_item.dart';
import '../helpers/driver_settlement_formatters.dart';
import '../localization/driver_settlement_localizations_x.dart';
import '../localization/driver_settlements_localizations.dart';

class DriverSettlementItemsSection extends StatelessWidget {
  final List<DriverSettlementItem> items;

  const DriverSettlementItemsSection({required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.sourceItems,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty)
          Text(strings.noSourceItems)
        else
          ...items.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                title: Text(context.driverSettlementItemLabel(item)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      Text(item.descriptionKey!),
                  ],
                ),
                trailing: Text(
                  formatDriverSettlementAmount(item.amount, localeName),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
