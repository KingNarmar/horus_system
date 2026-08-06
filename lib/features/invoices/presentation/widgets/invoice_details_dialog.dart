import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../domain/entities/invoice.dart';
import '../cubit/invoice_details_state.dart';
import '../helpers/invoice_formatters.dart';
import '../localization/invoice_failure_localizations_x.dart';
import '../localization/invoice_status_localizations_x.dart';
import '../localization/invoices_localizations.dart';

final class InvoiceDetailsDialog extends StatelessWidget {
  final InvoiceDetailsState state;
  final VoidCallback onRetry;
  final ValueChanged<Invoice> onIssue;
  final ValueChanged<Invoice> onCancel;

  const InvoiceDetailsDialog({
    required this.state,
    required this.onRetry,
    required this.onIssue,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currentState = state;
    if (currentState is InvoiceDetailsInitial ||
        currentState is InvoiceDetailsLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (currentState is InvoiceDetailsFailure) {
      return AlertDialog(
        title: Text(context.invoicesL10n.invoiceDetails),
        content: Text(
          context.localizedInvoiceFailure(currentState.failure),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.invoicesL10n.close),
          ),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.retryButton),
          ),
        ],
      );
    }

    if (currentState is! InvoiceDetailsLoaded) {
      return const SizedBox.shrink();
    }

    return _LoadedInvoiceDetailsDialog(
      state: currentState,
      onIssue: onIssue,
      onCancel: onCancel,
    );
  }
}

final class _LoadedInvoiceDetailsDialog extends StatelessWidget {
  final InvoiceDetailsLoaded state;
  final ValueChanged<Invoice> onIssue;
  final ValueChanged<Invoice> onCancel;

  const _LoadedInvoiceDetailsDialog({
    required this.state,
    required this.onIssue,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    final invoice = state.invoice;
    final fractionDigits = state.currentCompanyContext.company
            .baseCurrencyFractionDigits ??
        0;
    return AlertDialog(
      title: Text(strings.invoiceDetails),
      content: SizedBox(
        width: AppSizes.detailsDialogMaxWidth,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InvoiceSummary(
                invoice: invoice,
                currencyFractionDigits: fractionDigits,
              ),
              const SizedBox(height: AppSpacing.xl),
              _InvoiceLines(
                invoice: invoice,
                currencyFractionDigits: fractionDigits,
              ),
              const SizedBox(height: AppSpacing.xl),
              _InvoiceActivity(state: state),
              if (state.mutationFailure != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.localizedInvoiceFailure(state.mutationFailure!),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isMutationPending
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(strings.close),
        ),
        if (state.canCancel)
          OutlinedButton.icon(
            onPressed: state.isMutationPending
                ? null
                : () => onCancel(invoice),
            icon: const Icon(AppIcons.deactivate),
            label: Text(
              state.pendingAction == InvoiceDetailsAction.cancel
                  ? strings.cancelling
                  : strings.cancelInvoice,
            ),
          ),
        if (state.canIssue)
          FilledButton.icon(
            onPressed: state.isMutationPending
                ? null
                : () => onIssue(invoice),
            icon: const Icon(AppIcons.statusUpdate),
            label: Text(
              state.pendingAction == InvoiceDetailsAction.issue
                  ? strings.issuing
                  : strings.issue,
            ),
          ),
      ],
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
        _DetailRow(
          label: strings.number,
          value: invoice.number?.value ?? strings.draftNumber,
        ),
        _DetailRow(label: strings.customer, value: invoice.customer.name),
        _DetailRow(
          label: strings.status,
          value: invoice.status.localizedLabel(strings),
        ),
        _DetailRow(
          label: strings.issueDate,
          value: formatInvoiceDate(
            invoice.issueDate?.value,
            localeName,
            strings.unavailableValue,
          ),
        ),
        _DetailRow(
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
          _DetailRow(label: strings.notes, value: invoice.notes!),
        ],
        if (invoice.cancellationReason != null) ...[
          const Divider(),
          _DetailRow(
            label: strings.cancellationReason,
            value: invoice.cancellationReason!,
          ),
        ],
      ],
    );
  }
}

final class _InvoiceLines extends StatelessWidget {
  final Invoice invoice;
  final int currencyFractionDigits;

  const _InvoiceLines({
    required this.invoice,
    required this.currencyFractionDigits,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.invoiceLines,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...invoice.lines.map((line) {
          final reference =
              line.loadingOrderNumber ?? line.waybillNumber ?? line.tripId;
          return Card(
            child: ListTile(
              title: Text(strings.lineReference(reference)),
              subtitle: Text(
                formatInvoiceDate(
                  line.serviceDate,
                  localeName,
                  strings.unavailableValue,
                ),
              ),
              trailing: Text(
                formatInvoiceMoney(
                  line.amount,
                  fractionDigits: currencyFractionDigits,
                  localeName: localeName,
                ),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          );
        }),
      ],
    );
  }
}

final class _InvoiceActivity extends StatelessWidget {
  final InvoiceDetailsLoaded state;

  const _InvoiceActivity({required this.state});

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    if (state.isActivityLoading) {
      return Row(
        children: [
          const SizedBox.square(
            dimension: AppSizes.loadingIndicatorSm,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(strings.loadingActivity),
        ],
      );
    }

    if (state.activityFailure != null) {
      return Text(context.localizedInvoiceFailure(state.activityFailure!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.activity,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.activity.isEmpty)
          Text(strings.noActivity)
        else
          ...state.activity.map((log) => _AuditEntry(log: log)),
      ],
    );
  }
}

final class _AuditEntry extends StatelessWidget {
  final AuditLog log;

  const _AuditEntry({required this.log});

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final actor = log.actorDisplayName ??
        log.actorEmail ??
        context.invoicesL10n.unavailableValue;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(AppIcons.auditHistory),
      title: Text(_auditDescription(context, log.description)),
      subtitle: Text(
        '$actor • ${formatInvoiceDateTime(log.createdAt, localeName)}',
      ),
    );
  }
}

final class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
    return DefaultTextStyle.merge(
      style: emphasized ? const TextStyle(fontWeight: FontWeight.bold) : null,
      child: _DetailRow(
        label: label,
        value: formatInvoiceMoney(
          money,
          fractionDigits: fractionDigits,
          localeName: localeName,
        ),
      ),
    );
  }
}

String _auditDescription(BuildContext context, String description) {
  final strings = context.invoicesL10n;
  return switch (description) {
    'invoice_created' => strings.auditCreated,
    'invoice_updated' => strings.auditUpdated,
    'invoice_issued' => strings.auditIssued,
    'invoice_cancelled' => strings.auditCancelled,
    _ => strings.activity,
  };
}
