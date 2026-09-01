import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/company_role.dart';
import '../extensions/company_role_localization.dart';

class ChangeCompanyMemberRoleDialog extends StatefulWidget {
  final CompanyRole currentRole;
  final List<CompanyRole> availableRoles;

  const ChangeCompanyMemberRoleDialog({
    required this.currentRole,
    required this.availableRoles,
    super.key,
  });

  @override
  State<ChangeCompanyMemberRoleDialog> createState() =>
      _ChangeCompanyMemberRoleDialogState();
}

class _ChangeCompanyMemberRoleDialogState
    extends State<ChangeCompanyMemberRoleDialog> {
  CompanyRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    for (final role in widget.availableRoles) {
      if (role != widget.currentRole) {
        _selectedRole = role;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectableRoles = widget.availableRoles
        .where((role) => role != widget.currentRole)
        .toList(growable: false);

    return AlertDialog(
      title: Text(l10n.companyMemberChangeRoleTitle),
      content: SizedBox(
        width: AppSizes.formDialogMaxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.companyMemberChangeRoleDescription),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<CompanyRole>(
              initialValue: _selectedRole,
              decoration: InputDecoration(
                labelText: l10n.companyMemberRoleLabel,
              ),
              items: selectableRoles
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(role.localizedLabel(context)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (role) => setState(() => _selectedRole = role),
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
          onPressed: _selectedRole == null
              ? null
              : () => Navigator.of(context).pop(_selectedRole),
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }
}
