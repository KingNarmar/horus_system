import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../localization/invoices_localizations.dart';

final class InvoiceCancelDialog extends StatefulWidget {
  const InvoiceCancelDialog({super.key});

  @override
  State<InvoiceCancelDialog> createState() => _InvoiceCancelDialogState();
}

final class _InvoiceCancelDialogState extends State<InvoiceCancelDialog> {
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
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _reasonController,
            autofocus: true,
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(strings.cancelInvoice)),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_reasonController.text.trim());
  }
}
