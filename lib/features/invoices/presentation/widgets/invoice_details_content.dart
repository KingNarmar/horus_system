import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/widgets/adaptive_detail_row.dart';
import '../../domain/entities/invoice.dart';
import '../cubit/invoice_details_state.dart';
import '../helpers/invoice_formatters.dart';
import '../localization/invoice_failure_localizations_x.dart';
import '../localization/invoice_status_localizations_x.dart';
import '../localization/invoices_localizations.dart';
import 'invoice_activity_timeline.dart';
import 'invoice_lines_section.dart';

final class InvoiceDetailsContent extends StatelessWidget {
  final InvoiceDetailsLoaded state;

  const InvoiceDetailsContent({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final invoice = state.invoice;
    final strings = context.invoicesL10n;
    final fractionDigits =
        state.currentCompanyContext.company.baseCurrencyFractionDigits ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InvoiceDetailsSection(
          title: strings.details,
          child: _InvoiceSummary(
            invoice: invoice,
            currencyFractionDigits: fractionDigits,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _InvoiceDetailsSection(
          title: strings.invoiceLines,
          child: InvoiceLinesSection(
            invoice: invoice,
            currencyFractionDigits: fractionDigits,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _InvoiceDetailsSection(
          title: strings.activity,
          child: InvoiceActivityTimeline(state: state),
        ),
        if (state.mutationFailure != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.localizedInvoiceFailure(state.mutationFailure!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

final class _InvoiceDetailsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _InvoiceDetailsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

final class _InvoiceSummary extends StatelessWidget {
  final Invoice invoice;
  final int currencyFractionDigits;

  const _InvoiceSummary({
    required this.invoice,
    required this.currencyFractionDigits,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final totals = invoice.totals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdaptiveDetailRow(
          label: strings.number,
          value: invoice.number?.value ?? strings.draftNumber,
        ),
        AdaptiveDetailRow(
          label: strings.customer,
          value: invoice.customer.name,
        ),
        AdaptiveDetailRow(
          label: strings.status,
          value: invoice.status.localizedLabel(strings),
        ),
        AdaptiveDetailRow(
          label: strings.issueDate,
          value: formatInvoiceDate(
            invoice.issueDate?.value,
            localeName,
            strings.unavailableValue,
          ),
        ),
        AdaptiveDetailRow(
          label: strings.dueDate,
          value: formatInvoiceDate(
            invoice.dueDate?.value,
            localeName,
            strings.unavailableValue,
          ),
        ),
        const Divider(),
        _MoneyRow(
          label: strings.subtotal,
          money: totals.subtotal,
          fractionDigits: currencyFractionDigits,
        ),
        _MoneyRow(
          label: strings.discount,
          money: totals.discount,
          fractionDigits: currencyFractionDigits,
        ),
        _MoneyRow(
          label: strings.taxableAmount,
          money: totals.taxableAmount,
          fractionDigits: currencyFractionDigits,
        ),
        _MoneyRow(
          label: strings.tax,
          money: totals.taxAmount,
          fractionDigits: currencyFractionDigits,
        ),
        _MoneyRow(
          label: strings.total,
          money: totals.grandTotal,
          fractionDigits: currencyFractionDigits,
          emphasized: true,
        ),
        if (invoice.notes != null) ...[
          const Divider(),
          AdaptiveDetailRow(label: strings.notes, value: invoice.notes!),
        ],
        if (invoice.cancellationReason != null) ...[
          const Divider(),
          AdaptiveDetailRow(
            label: strings.cancellationReason,
            value: invoice.cancellationReason!,
          ),
        ],
      ],
    );
  }
}

final class _MoneyRow extends StatelessWidget {
  final String label;
  final Money money;
  final int fractionDigits;
  final bool emphasized;

  const _MoneyRow({
    required this.label,
    required this.money,
    required this.fractionDigits,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final style = emphasized
        ? const TextStyle(fontWeight: FontWeight.bold)
        : null;

    return AdaptiveDetailRow(
      label: label,
      labelStyle: style,
      valueStyle: style,
      value: formatInvoiceMoney(
        money,
        fractionDigits: fractionDigits,
        localeName: localeName,
      ),
    );
  }
}
