import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/invoice.dart';
import '../helpers/invoice_formatters.dart';
import '../localization/invoice_status_localizations_x.dart';
import '../localization/invoices_localizations.dart';

final class InvoicesList extends StatelessWidget {
  final List<Invoice> invoices;
  final int currencyFractionDigits;
  final ValueChanged<Invoice> onViewDetails;
  final bool useTable;

  const InvoicesList({
    required this.invoices,
    required this.currencyFractionDigits,
    required this.onViewDetails,
    required this.useTable,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return useTable
        ? _InvoicesTable(
            invoices: invoices,
            currencyFractionDigits: currencyFractionDigits,
            onViewDetails: onViewDetails,
          )
        : _InvoicesCards(
            invoices: invoices,
            currencyFractionDigits: currencyFractionDigits,
            onViewDetails: onViewDetails,
          );
  }
}

final class _InvoicesTable extends StatelessWidget {
  final List<Invoice> invoices;
  final int currencyFractionDigits;
  final ValueChanged<Invoice> onViewDetails;

  const _InvoicesTable({
    required this.invoices,
    required this.currencyFractionDigits,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(strings.number)),
            DataColumn(label: Text(strings.customer)),
            DataColumn(label: Text(strings.issueDate)),
            DataColumn(label: Text(strings.dueDate)),
            DataColumn(label: Text(strings.total), numeric: true),
            DataColumn(label: Text(strings.status)),
            DataColumn(label: Text(strings.actions)),
          ],
          rows: invoices.map((invoice) {
            return DataRow(
              cells: [
                DataCell(Text(invoice.number?.value ?? strings.draftNumber)),
                DataCell(Text(invoice.customer.name)),
                DataCell(
                  Text(
                    formatInvoiceDate(
                      invoice.issueDate?.value,
                      localeName,
                      strings.unavailableValue,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    formatInvoiceDate(
                      invoice.dueDate?.value,
                      localeName,
                      strings.unavailableValue,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    formatInvoiceMoney(
                      invoice.totals.grandTotal,
                      fractionDigits: currencyFractionDigits,
                      localeName: localeName,
                    ),
                  ),
                ),
                DataCell(Text(invoice.status.localizedLabel(strings))),
                DataCell(
                  IconButton(
                    onPressed: () => onViewDetails(invoice),
                    icon: const Icon(AppIcons.view),
                    tooltip: strings.details,
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

final class _InvoicesCards extends StatelessWidget {
  final List<Invoice> invoices;
  final int currencyFractionDigits;
  final ValueChanged<Invoice> onViewDetails;

  const _InvoicesCards({
    required this.invoices,
    required this.currencyFractionDigits,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return Column(
      children: invoices.map((invoice) {
        final number = invoice.number?.value ?? strings.draftNumber;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              number,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(invoice.customer.name),
                          ],
                        ),
                      ),
                      Chip(label: Text(invoice.status.localizedLabel(strings))),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _LabelValue(
                    label: strings.issueDate,
                    value: formatInvoiceDate(
                      invoice.issueDate?.value,
                      localeName,
                      strings.unavailableValue,
                    ),
                  ),
                  _LabelValue(
                    label: strings.dueDate,
                    value: formatInvoiceDate(
                      invoice.dueDate?.value,
                      localeName,
                      strings.unavailableValue,
                    ),
                  ),
                  _LabelValue(
                    label: strings.total,
                    value: formatInvoiceMoney(
                      invoice.totals.grandTotal,
                      fractionDigits: currencyFractionDigits,
                      localeName: localeName,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: OutlinedButton.icon(
                      onPressed: () => onViewDetails(invoice),
                      icon: const Icon(AppIcons.view),
                      label: Text(strings.details),
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

final class _LabelValue extends StatelessWidget {
  final String label;
  final String value;

  const _LabelValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
