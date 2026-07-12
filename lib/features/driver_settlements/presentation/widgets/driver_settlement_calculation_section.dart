import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/driver_settlement_calculation_result.dart';
import '../helpers/driver_settlement_formatters.dart';
import '../localization/driver_settlement_localizations_x.dart';
import '../localization/driver_settlements_localizations.dart';

class DriverSettlementCalculationSection extends StatelessWidget {
  final DriverSettlementCalculationResult calculation;
  final bool showTitle;

  const DriverSettlementCalculationSection({
    required this.calculation,
    this.showTitle = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final rows = [
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text(
            strings.calculationBreakdown,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(child: Text(row.$1)),
                Text(
                  formatDriverSettlementAmount(row.$2, localeName),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        Text(
          strings.labelValue(
            context.driverSettlementBalanceDirectionLabel(
              calculation.balanceDirection,
            ),
            formatDriverSettlementAmount(calculation.balanceAmount, localeName),
          ),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
