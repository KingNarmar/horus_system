import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/open_invoices_report.dart';
import '../helpers/reports_formatters.dart';
import '../localization/reports_localizations.dart';
import 'report_total_card.dart';

final class OpenInvoicesReportView extends StatelessWidget {
  final OpenInvoicesReport report;

  const OpenInvoicesReportView({required this.report, super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final digits = report.metadata.baseCurrencyFractionDigits;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportTotalCard(
          label: strings.totalOutstanding,
          value: formatReportMoney(
            money: report.totalOutstanding,
            fractionDigits: digits,
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
                  ? _InvoicesTable(report: report)
                  : _InvoicesCards(report: report);
            },
          ),
      ],
    );
  }
}

final class _InvoicesTable extends StatelessWidget {
  final OpenInvoicesReport report;

  const _InvoicesTable({required this.report});

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
            DataColumn(label: Text(strings.invoice)),
            DataColumn(label: Text(strings.customer)),
            DataColumn(label: Text(strings.issueDate)),
            DataColumn(label: Text(strings.dueDate)),
            DataColumn(label: Text(strings.status)),
            DataColumn(label: Text(strings.total), numeric: true),
            DataColumn(label: Text(strings.paid), numeric: true),
            DataColumn(label: Text(strings.remaining), numeric: true),
          ],
          rows: report.rows.map((row) {
            final invoice = row.invoice;
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    reportDisplayValue(
                      invoice.invoiceNumber,
                      invoice.invoiceId,
                    ),
                  ),
                ),
                DataCell(Text(invoice.customerName)),
                DataCell(Text(formatReportDate(invoice.issueDate, localeName))),
                DataCell(
                  Text(
                    invoice.dueDate == null
                        ? strings.notAvailable
                        : formatReportDate(invoice.dueDate!, localeName),
                  ),
                ),
                DataCell(Text(strings.invoiceStatusLabel(invoice.status))),
                DataCell(Text(_money(invoice.total, digits, localeName))),
                DataCell(Text(_money(row.paid, digits, localeName))),
                DataCell(Text(_money(row.remaining, digits, localeName))),
              ],
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

final class _InvoicesCards extends StatelessWidget {
  final OpenInvoicesReport report;

  const _InvoicesCards({required this.report});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final digits = report.metadata.baseCurrencyFractionDigits;
    return Column(
      children: report.rows.map((row) {
        final invoice = row.invoice;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reportDisplayValue(
                      invoice.invoiceNumber,
                      invoice.invoiceId,
                    ),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Line(strings.customer, invoice.customerName),
                  _Line(
                    strings.issueDate,
                    formatReportDate(invoice.issueDate, localeName),
                  ),
                  _Line(
                    strings.status,
                    strings.invoiceStatusLabel(invoice.status),
                  ),
                  _Line(
                    strings.total,
                    _money(invoice.total, digits, localeName),
                  ),
                  _Line(strings.paid, _money(row.paid, digits, localeName)),
                  _Line(
                    strings.remaining,
                    _money(row.remaining, digits, localeName),
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
