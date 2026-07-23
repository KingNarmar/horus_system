import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../constants/driver_settlement_presentation_constants.dart';
import '../localization/driver_settlements_localizations.dart';

class DriverSettlementVoidDialog extends StatefulWidget {
  const DriverSettlementVoidDialog({super.key});

  @override
  State<DriverSettlementVoidDialog> createState() =>
      _DriverSettlementVoidDialogState();
}

class _DriverSettlementVoidDialogState
    extends State<DriverSettlementVoidDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_reasonController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    return AlertDialog(
      title: Text(strings.voidTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.voidMessage),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(labelText: strings.voidReason),
              maxLines:
                  DriverSettlementPresentationConstants.voidReasonMaxLines,
              validator: (value) => (value ?? '').trim().isEmpty
                  ? strings.voidReasonRequired
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancelButton),
        ),
        FilledButton(onPressed: _submit, child: Text(strings.voidAction)),
      ],
    );
  }
}
