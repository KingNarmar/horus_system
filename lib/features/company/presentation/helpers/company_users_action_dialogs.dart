import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/company_invitation.dart';
import '../../domain/entities/company_role.dart';
import '../../domain/entities/company_user.dart';
import '../dialogs/change_company_member_role_dialog.dart';
import '../dialogs/company_action_confirmation_dialog.dart';
import '../dialogs/invite_company_user_dialog.dart';
import '../dialogs/transfer_company_ownership_dialog.dart';

abstract final class CompanyUsersActionDialogs {
  static Future<InviteCompanyUserInput?> showInvite(
    BuildContext context, {
    required List<CompanyRole> assignableRoles,
  }) {
    return showDialog<InviteCompanyUserInput>(
      context: context,
      builder: (_) => InviteCompanyUserDialog(
        assignableRoles: assignableRoles,
      ),
    );
  }

  static Future<CompanyRole?> showRoleChange(
    BuildContext context, {
    required CompanyUser user,
    required List<CompanyRole> availableRoles,
  }) {
    return showDialog<CompanyRole>(
      context: context,
      builder: (_) => ChangeCompanyMemberRoleDialog(
        currentRole: user.role,
        availableRoles: availableRoles,
      ),
    );
  }

  static Future<CompanyRole?> showOwnershipTransfer(
    BuildContext context, {
    required List<CompanyRole> sourceRoles,
  }) {
    return showDialog<CompanyRole>(
      context: context,
      builder: (_) => TransferCompanyOwnershipDialog(
        sourceRoles: sourceRoles,
      ),
    );
  }

  static Future<bool> confirmDeactivate(
    BuildContext context, {
    required CompanyUser user,
  }) {
    final l10n = context.l10n;
    return _confirm(
      context,
      title: l10n.companyMemberDeactivateTitle,
      message: l10n.companyMemberDeactivateMessage(_memberName(context, user)),
      confirmLabel: l10n.companyMemberDeactivateAction,
    );
  }

  static Future<bool> confirmReactivate(
    BuildContext context, {
    required CompanyUser user,
  }) {
    final l10n = context.l10n;
    return _confirm(
      context,
      title: l10n.companyMemberReactivateTitle,
      message: l10n.companyMemberReactivateMessage(_memberName(context, user)),
      confirmLabel: l10n.companyMemberReactivateAction,
    );
  }

  static Future<bool> confirmGrantOwnership(
    BuildContext context, {
    required CompanyUser user,
  }) {
    final l10n = context.l10n;
    return _confirm(
      context,
      title: l10n.companyOwnershipGrantTitle,
      message: l10n.companyOwnershipGrantMessage(_memberName(context, user)),
      confirmLabel: l10n.companyOwnershipGrantAction,
    );
  }

  static Future<bool> confirmResendInvitation(
    BuildContext context, {
    required CompanyInvitation invitation,
  }) {
    final l10n = context.l10n;
    return _confirm(
      context,
      title: l10n.companyInvitationResendTitle,
      message: l10n.companyInvitationResendMessage(invitation.email),
      confirmLabel: l10n.companyInvitationResendAction,
    );
  }

  static Future<bool> confirmRevokeInvitation(
    BuildContext context, {
    required CompanyInvitation invitation,
  }) {
    final l10n = context.l10n;
    return _confirm(
      context,
      title: l10n.companyInvitationRevokeTitle,
      message: l10n.companyInvitationRevokeMessage(invitation.email),
      confirmLabel: l10n.companyInvitationRevokeAction,
    );
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => CompanyActionConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
      ),
    );
    return result ?? false;
  }

  static String _memberName(BuildContext context, CompanyUser user) {
    final displayName = user.displayName?.trim();
    return displayName == null || displayName.isEmpty
        ? context.l10n.unknownUser
        : displayName;
  }
}
