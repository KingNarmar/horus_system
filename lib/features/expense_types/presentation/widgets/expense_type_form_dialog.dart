import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/validators/app_validators.dart';
import '../../domain/entities/expense_type.dart';
import '../localization/expense_types_localizations.dart';

class ExpenseTypeFormDialog extends StatefulWidget {
  final ExpenseType? expenseType;
  final Future<bool> Function(String name) onSubmit;

  const ExpenseTypeFormDialog({
    required this.onSubmit,
    this.expenseType,
    super.key,
  });

  @override
  State<ExpenseTypeFormDialog> createState() => _ExpenseTypeFormDialogState();
}

class _ExpenseTypeFormDialogState extends State<ExpenseTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.expenseType?.name);
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
    final l10n = context.expenseTypesL10n;
    return AlertDialog(
      title: Text(widget.expenseType == null ? l10n.addType : l10n.editType),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.formDialogMaxWidth,
        ),
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
            validator: (value) =>
                AppValidators.hasRequiredText(value) ? null : l10n.nameRequired,
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
