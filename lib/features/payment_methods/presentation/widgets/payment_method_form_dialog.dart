import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/payment_method.dart';
import '../localization/payment_methods_localizations.dart';

class PaymentMethodFormDialog extends StatefulWidget {
  final PaymentMethod? paymentMethod;
  final Future<bool> Function(String name) onSubmit;

  const PaymentMethodFormDialog({
    required this.onSubmit,
    this.paymentMethod,
    super.key,
  });

  @override
  State<PaymentMethodFormDialog> createState() =>
      _PaymentMethodFormDialogState();
}

class _PaymentMethodFormDialogState extends State<PaymentMethodFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.paymentMethod?.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final succeeded = await widget.onSubmit(_nameController.text);
    if (!mounted) return;

    if (succeeded) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.paymentMethodsL10n;
    return AlertDialog(
      title: Text(
        widget.paymentMethod == null ? l10n.addMethod : l10n.editMethod,
      ),
      content: SizedBox(
        width: AppSizes.formDialogMaxWidth,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            autofocus: true,
            enabled: !_isSaving,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.nameLabel,
              hintText: l10n.nameHint,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.nameRequired;
              }
              return null;
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: AppSizes.loadingIndicatorSm,
                      height: AppSizes.loadingIndicatorSm,
                      child: CircularProgressIndicator(
                        strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.saving),
                  ],
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
