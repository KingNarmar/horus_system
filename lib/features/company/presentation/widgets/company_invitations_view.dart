import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/company_invitation.dart';
import '../../domain/entities/company_invitation_status.dart';
import '../extensions/company_invitation_status_localization.dart';
import '../extensions/company_role_localization.dart';

enum _CompanyInvitationAction { resend, revoke }

class CompanyInvitationsView extends StatelessWidget {
  final List<CompanyInvitation> invitations;
  final bool actionInProgress;
  final ValueChanged<CompanyInvitation> onResend;
  final ValueChanged<CompanyInvitation> onRevoke;

  const CompanyInvitationsView({
    required this.invitations,
    required this.actionInProgress,
    required this.onResend,
    required this.onRevoke,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (invitations.isEmpty) {
      return Center(child: Text(context.l10n.companyInvitationsEmpty));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppSizes.dataTableBreakpoint) {
          return _desktopTable(context);
        }
        return _adaptiveCards(context);
      },
    );
  }

  Widget _desktopTable(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.companyInvitationsEmailColumn)),
            DataColumn(label: Text(l10n.companyInvitationsRoleColumn)),
            DataColumn(label: Text(l10n.companyInvitationsStatusColumn)),
            DataColumn(label: Text(l10n.companyInvitationsExpiresColumn)),
            DataColumn(label: Text(l10n.companyInvitationsLastSentColumn)),
            DataColumn(label: Text(l10n.companyInvitationsActionsColumn)),
          ],
          rows: invitations
              .map(
                (invitation) => DataRow(
                  cells: [
                    DataCell(Text(invitation.email)),
                    DataCell(Text(invitation.role.localizedLabel(context))),
                    DataCell(
                      Text(invitation.status.localizedLabel(context)),
                    ),
                    DataCell(Text(_date(context, invitation.expiresAt))),
                    DataCell(Text(_lastSent(context, invitation))),
                    DataCell(_actions(context, invitation)),
                  ],
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _adaptiveCards(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: invitations.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final invitation = invitations[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(AppIcons.invitations),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.email,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.l10n.invitationRoleLine(
                          invitation.role.localizedLabel(context),
                        ),
                      ),
                      Text(
                        context.l10n.invitationStatusLine(
                          invitation.status.localizedLabel(context),
                        ),
                      ),
                      Text(
                        context.l10n.invitationExpiresLine(
                          _date(context, invitation.expiresAt),
                        ),
                      ),
                      Text(
                        context.l10n.companyInvitationLastSentLine(
                          _lastSent(context, invitation),
                        ),
                      ),
                    ],
                  ),
                ),
                _actions(context, invitation),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actions(BuildContext context, CompanyInvitation invitation) {
    if (invitation.status != CompanyInvitationStatus.pending) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<_CompanyInvitationAction>(
      enabled: !actionInProgress,
      icon: const Icon(AppIcons.moreActions),
      onSelected: (action) {
        switch (action) {
          case _CompanyInvitationAction.resend:
            onResend(invitation);
            break;
          case _CompanyInvitationAction.revoke:
            onRevoke(invitation);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _CompanyInvitationAction.resend,
          child: Row(
            children: [
              const Icon(AppIcons.resend, size: AppSizes.iconSm),
              const SizedBox(width: AppSpacing.sm),
              Text(context.l10n.companyInvitationResendAction),
            ],
          ),
        ),
        PopupMenuItem(
          value: _CompanyInvitationAction.revoke,
          child: Row(
            children: [
              const Icon(AppIcons.deactivate, size: AppSizes.iconSm),
              const SizedBox(width: AppSpacing.sm),
              Text(context.l10n.companyInvitationRevokeAction),
            ],
          ),
        ),
      ],
    );
  }

  String _date(BuildContext context, DateTime value) {
    return MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
  }

  String _lastSent(BuildContext context, CompanyInvitation invitation) {
    final lastSentAt = invitation.lastSentAt;
    if (lastSentAt == null) return context.l10n.companyInvitationNeverSent;
    return _date(context, lastSentAt);
  }
}
