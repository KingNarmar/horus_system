import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/localization/app_localizations_extension.dart';

class CompanyActionConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;

  const CompanyActionConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: AppSizes.formDialogMaxWidth,
        child: Text(message),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
