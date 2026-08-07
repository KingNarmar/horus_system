import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../localization/invoices_localizations.dart';

final class InvoiceCancelForm extends StatefulWidget {
  final bool isSubmitting;
  final String? failureMessage;
  final VoidCallback onBack;
  final Future<void> Function(String reason) onSubmit;

  const InvoiceCancelForm({
    required this.isSubmitting,
    required this.onBack,
    required this.onSubmit,
    this.failureMessage,
    super.key,
  });

  @override
  State<InvoiceCancelForm> createState() => _InvoiceCancelFormState();
}

final class _InvoiceCancelFormState extends State<InvoiceCancelForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    return AlertDialog(
      title: Text(strings.cancelTitle),
      content: SizedBox(
        width: AppSizes.formDialogMaxWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _reasonController,
                  autofocus: true,
                  enabled: !widget.isSubmitting,
                  decoration: InputDecoration(
                    labelText: strings.cancellationReason,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    return value == null || value.trim().isEmpty
                        ? strings.cancellationReasonRequired
                        : null;
                  },
                ),
                if (widget.failureMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    widget.failureMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isSubmitting ? null : widget.onBack,
          child: Text(strings.details),
        ),
        FilledButton.icon(
          key: const ValueKey('invoiceCancelSubmitButton'),
          onPressed: widget.isSubmitting ? null : _submit,
          icon: widget.isSubmitting
              ? const SizedBox.square(
                  dimension: AppSizes.loadingIndicatorSm,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
                  ),
                )
              : const Icon(AppIcons.deactivate),
          label: Text(
            widget.isSubmitting ? strings.cancelling : strings.cancelInvoice,
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || widget.isSubmitting) return;
    await widget.onSubmit(_reasonController.text.trim());
  }
}
