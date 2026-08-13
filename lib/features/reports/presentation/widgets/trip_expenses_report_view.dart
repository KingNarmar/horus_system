import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/trip_expenses_report.dart';
import '../helpers/reports_formatters.dart';
import '../localization/reports_localizations.dart';
import 'report_total_card.dart';

final class TripExpensesReportView extends StatelessWidget {
  final TripExpensesReport report;

  const TripExpensesReportView({required this.report, super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final fractionDigits = report.metadata.baseCurrencyFractionDigits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportTotalCard(
          label: strings.totalExpenses,
          value: formatReportMoney(
            money: report.totalExpenses,
            fractionDigits: fractionDigits,
            localeName: localeName,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (report.rows.isEmpty)
          Text(strings.noRows)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              return constraints.maxWidth >= AppSizes.dataTableBreakpoint
                  ? _ExpensesTable(report: report)
                  : _ExpensesCards(report: report);
            },
          ),
      ],
    );
  }
}

final class _ExpensesTable extends StatelessWidget {
  final TripExpensesReport report;

  const _ExpensesTable({required this.report});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final fractionDigits = report.metadata.baseCurrencyFractionDigits;
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(strings.date)),
            DataColumn(label: Text(strings.trip)),
            DataColumn(label: Text(strings.customer)),
            DataColumn(label: Text(strings.expense)),
            DataColumn(label: Text(strings.paidBy)),
            DataColumn(label: Text(strings.amount), numeric: true),
          ],
          rows: report.rows.map((row) {
            return DataRow(
              cells: [
                DataCell(Text(formatReportDate(row.expenseDate, localeName))),
                DataCell(Text(reportDisplayValue(row.tripNumber, row.tripId))),
                DataCell(Text(row.customerName)),
                DataCell(Text(row.expenseName)),
                DataCell(Text(strings.paidByLabel(row.paidBy))),
                DataCell(
                  Text(
                    formatReportMoney(
                      money: row.amount,
                      fractionDigits: fractionDigits,
                      localeName: localeName,
                    ),
                  ),
                ),
              ],
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

final class _ExpensesCards extends StatelessWidget {
  final TripExpensesReport report;

  const _ExpensesCards({required this.report});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final fractionDigits = report.metadata.baseCurrencyFractionDigits;
    return Column(
      children: report.rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.expenseName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Line(
                    strings.date,
                    formatReportDate(row.expenseDate, localeName),
                  ),
                  _Line(
                    strings.trip,
                    reportDisplayValue(row.tripNumber, row.tripId),
                  ),
                  _Line(strings.customer, row.customerName),
                  _Line(strings.paidBy, strings.paidByLabel(row.paidBy)),
                  _Line(
                    strings.amount,
                    formatReportMoney(
                      money: row.amount,
                      fractionDigits: fractionDigits,
                      localeName: localeName,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

final class _Line extends StatelessWidget {
  final String label;
  final String value;

  const _Line(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text('$label: $value'),
    );
  }
}
