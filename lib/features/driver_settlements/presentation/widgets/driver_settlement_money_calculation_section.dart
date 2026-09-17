import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/widgets/adaptive_detail_row.dart';
import '../../domain/entities/driver_settlement_money_calculation_result.dart';
import '../helpers/driver_settlement_formatters.dart';
import '../localization/driver_settlement_localizations_x.dart';
import '../localization/driver_settlements_localizations.dart';

final class DriverSettlementMoneyCalculationSection extends StatelessWidget {
  final DriverSettlementMoneyCalculationResult calculation;
  final int currencyFractionDigits;

  const DriverSettlementMoneyCalculationSection({
    required this.calculation,
    required this.currencyFractionDigits,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    final rows = <(String, Money)>[
      (strings.openingBalance, calculation.openingDriverBalance),
      (strings.advancesTotal, calculation.advancesTotal),
      (strings.driverPaidTripExpenses, calculation.driverPaidTripExpensesTotal),
      (strings.returnedCash, calculation.returnedCashTotal),
      (strings.deductionsTotal, calculation.deductionsTotal),
      (
        strings.settlementDeductionsTotal,
        calculation.settlementDeductionsTotal,
      ),
      (strings.grossSalary, calculation.grossSalary),
      (strings.salaryDeductions, calculation.salaryDeductionsTotal),
      (strings.balanceDeduction, calculation.balanceDeductionApplied),
      (strings.netSalary, calculation.netSalaryPayable),
      (strings.closingBalance, calculation.closingDriverBalance),
    ];
    final valueStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.calculationBreakdown,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...rows.map(
          (row) => AdaptiveDetailRow(
            label: row.$1,
            value: formatDriverSettlementMoney(
              row.$2,
              currencyFractionDigits: currencyFractionDigits,
            ),
            valueStyle: valueStyle,
          ),
        ),
        const Divider(),
        AdaptiveDetailRow(
          label: context.driverSettlementBalanceDirectionLabel(
            calculation.balanceDirection,
          ),
          value: formatDriverSettlementMoney(
            calculation.balanceAmount,
            currencyFractionDigits: currencyFractionDigits,
          ),
          labelStyle: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          valueStyle: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
