import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/adaptive_detail_row.dart';
import '../../domain/entities/driver_settlement.dart';
import '../cubit/driver_settlements_state.dart';
import '../helpers/driver_settlement_formatters.dart';
import '../localization/driver_settlement_localizations_x.dart';
import '../localization/driver_settlements_localizations.dart';

class DriverSettlementsList extends StatelessWidget {
  final DriverSettlementsLoaded state;
  final List<DriverSettlement> settlements;
  final ValueChanged<DriverSettlement> onViewDetails;

  const DriverSettlementsList({
    required this.state,
    required this.settlements,
    required this.onViewDetails,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppSizes.dataTableBreakpoint) {
          return _DriverSettlementsTable(
            state: state,
            settlements: settlements,
            onViewDetails: onViewDetails,
          );
        }
        return _DriverSettlementCards(
          state: state,
          settlements: settlements,
          onViewDetails: onViewDetails,
        );
      },
    );
  }
}

class _DriverSettlementsTable extends StatelessWidget {
  final DriverSettlementsLoaded state;
  final List<DriverSettlement> settlements;
  final ValueChanged<DriverSettlement> onViewDetails;

  const _DriverSettlementsTable({
    required this.state,
    required this.settlements,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(strings.driverLabel)),
            DataColumn(label: Text(strings.period)),
            DataColumn(label: Text(strings.status)),
            DataColumn(label: Text(strings.netSalary), numeric: true),
            DataColumn(label: Text(strings.closingBalance), numeric: true),
            DataColumn(label: Text(strings.details)),
          ],
          rows: settlements.map((settlement) {
            final calculation = settlement.calculation;
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    state.driverLabel(settlement.driverId) ??
                        strings.unknownDriver,
                  ),
                ),
                DataCell(
                  Text(
                    strings.periodValue(
                      formatDriverSettlementDate(
                        settlement.period.start,
                        localeName,
                      ),
                      formatDriverSettlementDate(
                        settlement.period.end,
                        localeName,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(context.driverSettlementStatusLabel(settlement.status)),
                ),
                DataCell(
                  Text(
                    formatDriverSettlementAmount(
                      calculation.netSalaryPayable,
                      localeName,
                    ),
                  ),
                ),
                DataCell(
                  Tooltip(
                    message: context.driverSettlementBalanceDirectionLabel(
                      calculation.balanceDirection,
                    ),
                    child: Text(
                      formatDriverSettlementAmount(
                        calculation.closingDriverBalance,
                        localeName,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    tooltip: strings.details,
                    onPressed: () => onViewDetails(settlement),
                    icon: const Icon(AppIcons.view),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DriverSettlementCards extends StatelessWidget {
  final DriverSettlementsLoaded state;
  final List<DriverSettlement> settlements;
  final ValueChanged<DriverSettlement> onViewDetails;

  const _DriverSettlementCards({
    required this.state,
    required this.settlements,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: settlements
          .map(
            (settlement) => _DriverSettlementCard(
              settlement: settlement,
              driverName:
                  state.driverLabel(settlement.driverId) ??
                  context.driverSettlementsL10n.unknownDriver,
              onViewDetails: onViewDetails,
            ),
          )
          .toList(),
    );
  }
}

class _DriverSettlementCard extends StatelessWidget {
  final DriverSettlement settlement;
  final String driverName;
  final ValueChanged<DriverSettlement> onViewDetails;

  const _DriverSettlementCard({
    required this.settlement,
    required this.driverName,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final calculation = settlement.calculation;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    driverName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Chip(
                  label: Text(
                    context.driverSettlementStatusLabel(settlement.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AdaptiveDetailRow(
              label: strings.period,
              value: strings.periodValue(
                formatDriverSettlementDate(settlement.period.start, localeName),
                formatDriverSettlementDate(settlement.period.end, localeName),
              ),
            ),
            AdaptiveDetailRow(
              label: strings.netSalary,
              value: formatDriverSettlementAmount(
                calculation.netSalaryPayable,
                localeName,
              ),
            ),
            AdaptiveDetailRow(
              label: context.driverSettlementBalanceDirectionLabel(
                calculation.balanceDirection,
              ),
              value: formatDriverSettlementAmount(
                calculation.balanceAmount,
                localeName,
              ),
            ),
            if (settlement.notes != null && settlement.notes!.trim().isNotEmpty)
              Text(settlement.notes!),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlinedButton.icon(
                onPressed: () => onViewDetails(settlement),
                icon: const Icon(AppIcons.view),
                label: Text(strings.details),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
