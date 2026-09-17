import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/adaptive_detail_row.dart';
import '../../domain/entities/driver_settlement_item_source_type.dart';
import '../../domain/entities/driver_settlement_money_item.dart';
import '../helpers/driver_settlement_formatters.dart';
import '../localization/driver_settlement_localizations_x.dart';
import '../localization/driver_settlements_localizations.dart';

final class DriverSettlementMoneyItemsSection extends StatelessWidget {
  final List<DriverSettlementMoneyItem> items;
  final int currencyFractionDigits;

  const DriverSettlementMoneyItemsSection({
    required this.items,
    required this.currencyFractionDigits,
    super.key,
  });

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
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdaptiveDetailRow(
                      label: _label(item, strings),
                      value: formatDriverSettlementMoney(
                        item.amount,
                        currencyFractionDigits: currencyFractionDigits,
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

  String _label(
    DriverSettlementMoneyItem item,
    DriverSettlementsLocalizations strings,
  ) {
    return switch (item.labelKey) {
      'driver_settlement_item_advance' => strings.itemAdvance,
      'driver_settlement_item_driver_charge' => strings.itemDriverCharge,
      'driver_settlement_item_cash_return' => strings.itemCashReturn,
      'driver_settlement_item_deduction' => strings.itemDriverCharge,
      'driver_settlement_item_trip_expense' => strings.itemTripExpense,
      _ => switch (item.sourceType) {
        DriverSettlementItemSourceType.driverFinancialMovement =>
          strings.itemFinancialMovement,
        DriverSettlementItemSourceType.tripExpense => strings.itemTripExpense,
        DriverSettlementItemSourceType.manualAdjustment =>
          strings.itemManualAdjustment,
      },
    };
  }
}
