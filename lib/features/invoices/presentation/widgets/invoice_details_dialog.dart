import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/invoice.dart';
import '../cubit/invoice_details_state.dart';
import '../localization/invoice_failure_localizations_x.dart';
import '../localization/invoices_localizations.dart';
import 'invoice_cancel_form.dart';
import 'invoice_details_content.dart';
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
      return _InvoiceDialogShell(
        title: strings.invoiceDetails,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (currentState is InvoiceDetailsFailure) {
      return _InvoiceDialogShell(
        title: strings.invoiceDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.localizedInvoiceFailure(currentState.failure),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlinedButton(
                onPressed: widget.onRetry,
                child: Text(context.l10n.retryButton),
              ),
            ),
          ],
        ),
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
      return _InvoiceDialogShell(
        title: strings.issueTitle,
        canClose: !currentState.isMutationPending,
        child: InvoiceIssueForm(
          initialDate: invoice.issueDate?.value ?? invoice.createdAt,
          issueDate: invoice.issueDate?.value,
          dueDate: invoice.dueDate?.value,
          isSubmitting:
              currentState.pendingAction == InvoiceDetailsAction.issue,
          failureMessage: failureMessage,
          onBack: () => _showView(_InvoiceDetailsView.details),
          onSubmit: (dates) => _issue(invoice, dates),
        ),
      );
    }

    if (view == _InvoiceDetailsView.cancel) {
      return _InvoiceDialogShell(
        title: strings.cancelTitle,
        canClose: !currentState.isMutationPending,
        child: InvoiceCancelForm(
          isSubmitting:
              currentState.pendingAction == InvoiceDetailsAction.cancel,
          failureMessage: failureMessage,
          onBack: () => _showView(_InvoiceDetailsView.details),
          onSubmit: (reason) => _cancel(invoice, reason),
        ),
      );
    }

    final actionButtons = _detailsActionButtons(context, currentState);
    return _InvoiceDialogShell(
      title: strings.invoiceDetails,
      canClose: !currentState.isMutationPending,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InvoiceDetailsContent(state: currentState),
          if (actionButtons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: actionButtons,
            ),
          ],
        ],
      ),
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

  List<Widget> _detailsActionButtons(
    BuildContext context,
    InvoiceDetailsLoaded state,
  ) {
    final strings = context.invoicesL10n;
    return [
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

final class _InvoiceDialogShell extends StatelessWidget {
  final String title;
  final Widget child;
  final bool canClose;

  const _InvoiceDialogShell({
    required this.title,
    required this.child,
    this.canClose = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.detailsDialogMaxWidth,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('invoiceDialogCloseButton'),
                    onPressed: canClose
                        ? () => Navigator.of(context).pop()
                        : null,
                    icon: const Icon(AppIcons.clear),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
