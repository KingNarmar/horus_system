import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/company_role.dart';
import '../extensions/company_role_localization.dart';

class TransferCompanyOwnershipDialog extends StatefulWidget {
  final List<CompanyRole> sourceRoles;

  const TransferCompanyOwnershipDialog({required this.sourceRoles, super.key});

  @override
  State<TransferCompanyOwnershipDialog> createState() =>
      _TransferCompanyOwnershipDialogState();
}

class _TransferCompanyOwnershipDialogState
    extends State<TransferCompanyOwnershipDialog> {
  CompanyRole? _sourceNewRole;

  @override
  void initState() {
    super.initState();
    if (widget.sourceRoles.contains(CompanyRole.admin)) {
      _sourceNewRole = CompanyRole.admin;
    } else if (widget.sourceRoles.isNotEmpty) {
      _sourceNewRole = widget.sourceRoles.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.companyOwnershipTransferTitle),
      content: SizedBox(
        width: AppSizes.formDialogMaxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.companyOwnershipTransferWarning),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<CompanyRole>(
              initialValue: _sourceNewRole,
              decoration: InputDecoration(
                labelText: l10n.companyOwnershipSourceRoleLabel,
              ),
              items: widget.sourceRoles
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(role.localizedLabel(context)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (role) => setState(() => _sourceNewRole = role),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: _sourceNewRole == null
              ? null
              : () => Navigator.of(context).pop(_sourceNewRole),
          child: Text(l10n.companyOwnershipTransferButton),
        ),
      ],
    );
  }
}
