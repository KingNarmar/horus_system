import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../trips/presentation/localization/trips_localizations_x.dart';
import '../../domain/entities/trip_net_profit_report.dart';
import '../helpers/reports_formatters.dart';
import '../localization/reports_localizations.dart';
import 'report_total_card.dart';

final class TripNetProfitReportView extends StatelessWidget {
  final TripNetProfitReport report;

  const TripNetProfitReportView({required this.report, super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final digits = report.metadata.baseCurrencyFractionDigits;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            ReportTotalCard(
              label: strings.totalFreight,
              value: formatReportMoney(
                money: report.totalFreight,
                fractionDigits: digits,
                localeName: localeName,
              ),
            ),
            ReportTotalCard(
              label: strings.totalExpenses,
              value: formatReportMoney(
                money: report.totalExpenses,
                fractionDigits: digits,
                localeName: localeName,
              ),
            ),
            ReportTotalCard(
              label: strings.totalNetProfit,
              value: formatReportMoney(
                money: report.totalNetProfit,
                fractionDigits: digits,
                localeName: localeName,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (report.rows.isEmpty)
          Text(strings.noRows)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              return constraints.maxWidth >= AppSizes.dataTableBreakpoint
                  ? _ProfitTable(report: report)
                  : _ProfitCards(report: report);
            },
          ),
      ],
    );
  }
}

final class _ProfitTable extends StatelessWidget {
  final TripNetProfitReport report;

  const _ProfitTable({required this.report});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final digits = report.metadata.baseCurrencyFractionDigits;
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(strings.trip)),
            DataColumn(label: Text(strings.date)),
            DataColumn(label: Text(strings.customer)),
            DataColumn(label: Text(strings.status)),
            DataColumn(label: Text(strings.freight), numeric: true),
            DataColumn(label: Text(strings.totalExpenses), numeric: true),
            DataColumn(label: Text(strings.netProfit), numeric: true),
          ],
          rows: report.rows
              .map((row) {
                final trip = row.trip;
                return DataRow(
                  cells: [
                    DataCell(
                      Text(reportDisplayValue(trip.tripNumber, trip.tripId)),
                    ),
                    DataCell(
                      Text(formatReportDate(trip.operationalDate, localeName)),
                    ),
                    DataCell(Text(trip.customerName)),
                    DataCell(Text(context.l10n.tripStatusLabel(trip.status))),
                    DataCell(Text(_money(trip.freight, digits, localeName))),
                    DataCell(
                      Text(_money(row.totalExpenses, digits, localeName)),
                    ),
                    DataCell(Text(_money(row.netProfit, digits, localeName))),
                  ],
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

final class _ProfitCards extends StatelessWidget {
  final TripNetProfitReport report;

  const _ProfitCards({required this.report});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final digits = report.metadata.baseCurrencyFractionDigits;
    return Column(
      children: report.rows
          .map((row) {
            final trip = row.trip;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reportDisplayValue(trip.tripNumber, trip.tripId),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _Line(
                        strings.date,
                        formatReportDate(trip.operationalDate, localeName),
                      ),
                      _Line(strings.customer, trip.customerName),
                      _Line(
                        strings.status,
                        context.l10n.tripStatusLabel(trip.status),
                      ),
                      _Line(
                        strings.freight,
                        _money(trip.freight, digits, localeName),
                      ),
                      _Line(
                        strings.totalExpenses,
                        _money(row.totalExpenses, digits, localeName),
                      ),
                      _Line(
                        strings.netProfit,
                        _money(row.netProfit, digits, localeName),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

String _money(Money money, int digits, String localeName) {
  return formatReportMoney(
    money: money,
    fractionDigits: digits,
    localeName: localeName,
  );
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
