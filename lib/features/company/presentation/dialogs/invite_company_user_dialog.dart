import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/company_role.dart';
import '../extensions/company_role_localization.dart';

class InviteCompanyUserInput {
  final String email;
  final CompanyRole role;

  const InviteCompanyUserInput({required this.email, required this.role});
}

class InviteCompanyUserDialog extends StatefulWidget {
  final List<CompanyRole> assignableRoles;

  const InviteCompanyUserDialog({required this.assignableRoles, super.key});

  @override
  State<InviteCompanyUserDialog> createState() =>
      _InviteCompanyUserDialogState();
}

class _InviteCompanyUserDialogState extends State<InviteCompanyUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  CompanyRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.assignableRoles.isEmpty
        ? null
        : widget.assignableRoles.first;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final role = _selectedRole;
    if (role == null) return;

    Navigator.of(context).pop(
      InviteCompanyUserInput(email: _emailController.text.trim(), role: role),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.companyInviteDialogTitle),
      content: SizedBox(
        width: AppSizes.formDialogMaxWidth,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.companyInviteDialogDescription),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.companyInviteEmailLabel,
                ),
                validator: (value) {
                  final email = (value ?? '').trim();
                  if (email.isEmpty || !email.contains('@')) {
                    return l10n.failureCompanyInvitationEmailInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<CompanyRole>(
                initialValue: _selectedRole,
                decoration: InputDecoration(
                  labelText: l10n.companyInviteRoleLabel,
                ),
                items: widget.assignableRoles
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: widget.assignableRoles.isEmpty ? null : _submit,
          child: Text(l10n.companyInviteSendButton),
        ),
      ],
    );
  }
}
