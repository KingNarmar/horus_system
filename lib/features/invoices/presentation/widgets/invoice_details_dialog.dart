import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/widgets/adaptive_detail_row.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../domain/entities/invoice.dart';
import '../cubit/invoice_details_state.dart';
import '../helpers/invoice_formatters.dart';
import '../localization/invoice_failure_localizations_x.dart';
import '../localization/invoice_status_localizations_x.dart';
import '../localization/invoices_localizations.dart';
import 'invoice_cancel_form.dart';
import 'invoice_issue_form.dart';

enum _InvoiceDetailsView { details, issue, cancel }

final class InvoiceDetailsDialog extends StatefulWidget {
  final InvoiceDetailsState state;
  final VoidCallback onRetry;
  final Future<bool> Function(Invoice invoice, InvoiceIssueDates dates) onIssue;
  final Future<bool> Function(Invoice invoice, String reason) onCancel;

  const InvoiceDetailsDialog({
    required this.state,
    required this.onRetry,
    required this.onIssue,
    required this.onCancel,
    super.key,
  });

  @override
  State<InvoiceDetailsDialog> createState() => _InvoiceDetailsDialogState();
}

final class _InvoiceDetailsDialogState extends State<InvoiceDetailsDialog> {
  _InvoiceDetailsView _view = _InvoiceDetailsView.details;

  @override
  Widget build(BuildContext context) {
    final currentState = widget.state;
    final strings = context.invoicesL10n;

    if (currentState is InvoiceDetailsInitial ||
        currentState is InvoiceDetailsLoading) {
      return AlertDialog(
        title: Text(strings.invoiceDetails),
        content: const SizedBox(
          width: AppSizes.detailsDialogMaxWidth,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    if (currentState is InvoiceDetailsFailure) {
      return AlertDialog(
        title: Text(strings.invoiceDetails),
        content: SizedBox(
          width: AppSizes.detailsDialogMaxWidth,
          child: Text(
            context.localizedInvoiceFailure(currentState.failure),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.close),
          ),
          OutlinedButton(
            onPressed: widget.onRetry,
            child: Text(context.l10n.retryButton),
          ),
        ],
      );
    }

    if (currentState is! InvoiceDetailsLoaded) {
      return const SizedBox.shrink();
    }

    final view = _effectiveView(currentState);
    final invoice = currentState.invoice;
    final failureMessage = currentState.mutationFailure == null
        ? null
        : context.localizedInvoiceFailure(currentState.mutationFailure!);

    if (view == _InvoiceDetailsView.issue) {
      return InvoiceIssueForm(
        initialDate: invoice.issueDate?.value ?? invoice.createdAt,
        issueDate: invoice.issueDate?.value,
        dueDate: invoice.dueDate?.value,
        isSubmitting: currentState.pendingAction == InvoiceDetailsAction.issue,
        failureMessage: failureMessage,
        onBack: () => _showView(_InvoiceDetailsView.details),
        onSubmit: (dates) => _issue(invoice, dates),
      );
    }

    if (view == _InvoiceDetailsView.cancel) {
      return InvoiceCancelForm(
        isSubmitting: currentState.pendingAction == InvoiceDetailsAction.cancel,
        failureMessage: failureMessage,
        onBack: () => _showView(_InvoiceDetailsView.details),
        onSubmit: (reason) => _cancel(invoice, reason),
      );
    }

    return AlertDialog(
      title: Text(strings.invoiceDetails),
      content: SizedBox(
        width: AppSizes.detailsDialogMaxWidth,
        child: SingleChildScrollView(
          child: _LoadedInvoiceDetails(state: currentState),
        ),
      ),
      actions: _detailsActions(context, currentState),
    );
  }

  _InvoiceDetailsView _effectiveView(InvoiceDetailsLoaded state) {
    if (_view == _InvoiceDetailsView.issue && !state.canIssue) {
      return _InvoiceDetailsView.details;
    }
    if (_view == _InvoiceDetailsView.cancel && !state.canCancel) {
      return _InvoiceDetailsView.details;
    }
    return _view;
  }

  List<Widget> _detailsActions(
    BuildContext context,
    InvoiceDetailsLoaded state,
  ) {
    final strings = context.invoicesL10n;
    return [
      TextButton(
        onPressed: state.isMutationPending
            ? null
            : () => Navigator.of(context).pop(),
        child: Text(strings.close),
      ),
      if (state.canCancel)
        OutlinedButton.icon(
          key: const ValueKey('invoiceCancelActionButton'),
          onPressed: state.isMutationPending
              ? null
              : () => _showView(_InvoiceDetailsView.cancel),
          icon: const Icon(AppIcons.deactivate),
          label: Text(strings.cancelInvoice),
        ),
      if (state.canIssue)
        FilledButton.icon(
          key: const ValueKey('invoiceIssueActionButton'),
          onPressed: state.isMutationPending
              ? null
              : () => _showView(_InvoiceDetailsView.issue),
          icon: const Icon(AppIcons.statusUpdate),
          label: Text(strings.issue),
        ),
    ];
  }

  void _showView(_InvoiceDetailsView view) {
    if (!mounted) return;
    setState(() => _view = view);
  }

  Future<void> _issue(Invoice invoice, InvoiceIssueDates dates) async {
    final succeeded = await widget.onIssue(invoice, dates);
    if (!mounted || !succeeded) return;
    setState(() => _view = _InvoiceDetailsView.details);
  }

  Future<void> _cancel(Invoice invoice, String reason) async {
    final succeeded = await widget.onCancel(invoice, reason);
    if (!mounted || !succeeded) return;
    setState(() => _view = _InvoiceDetailsView.details);
  }
}

final class _LoadedInvoiceDetails extends StatelessWidget {
  final InvoiceDetailsLoaded state;

  const _LoadedInvoiceDetails({required this.state});

  @override
  Widget build(BuildContext context) {
    final invoice = state.invoice;
    final fractionDigits =
        state.currentCompanyContext.company.baseCurrencyFractionDigits ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InvoiceSummary(
          invoice: invoice,
          currencyFractionDigits: fractionDigits,
        ),
        const SizedBox(height: AppSpacing.xl),
        _InvoiceLines(invoice: invoice, currencyFractionDigits: fractionDigits),
        const SizedBox(height: AppSpacing.xl),
        _InvoiceActivity(state: state),
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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...invoice.lines.map(
          (line) => _InvoiceLineCard(
            title: strings.lineReference(
              formatInvoiceLineReference(
                line,
                fallback: strings.unavailableValue,
              ),
            ),
            date: formatInvoiceDate(
              line.serviceDate,
              localeName,
              strings.unavailableValue,
            ),
            amount: formatInvoiceMoney(
              line.amount,
              fractionDigits: currencyFractionDigits,
              localeName: localeName,
            ),
          ),
        ),
      ],
    );
  }
}

final class _InvoiceLineCard extends StatelessWidget {
  final String title;
  final String date;
  final String amount;

  const _InvoiceLineCard({
    required this.title,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < AppSizes.detailsStackBreakpoint) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(date),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    amount,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          return ListTile(
            title: Text(title),
            subtitle: Text(date),
            trailing: Text(
              amount,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
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
          Expanded(child: Text(strings.loadingActivity)),
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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
    final actor =
        log.actorDisplayName ??
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
