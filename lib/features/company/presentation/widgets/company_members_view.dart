import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/company_role.dart';
import '../../domain/entities/company_user.dart';
import '../../domain/entities/current_company_context.dart';
import '../../domain/policies/company_invitation_policy.dart';
import '../../domain/policies/company_membership_management_policy.dart';
import '../extensions/company_role_localization.dart';

enum _CompanyMemberAction {
  changeRole,
  deactivate,
  reactivate,
  grantOwnership,
  transferOwnership,
}

class CompanyMembersView extends StatelessWidget {
  final List<CompanyUser> users;
  final CurrentCompanyContext currentCompanyContext;
  final String? currentUserId;
  final bool actionInProgress;
  final ValueChanged<CompanyUser> onChangeRole;
  final ValueChanged<CompanyUser> onDeactivate;
  final ValueChanged<CompanyUser> onReactivate;
  final ValueChanged<CompanyUser> onGrantOwnership;
  final ValueChanged<CompanyUser> onTransferOwnership;

  const CompanyMembersView({
    required this.users,
    required this.currentCompanyContext,
    required this.currentUserId,
    required this.actionInProgress,
    required this.onChangeRole,
    required this.onDeactivate,
    required this.onReactivate,
    required this.onGrantOwnership,
    required this.onTransferOwnership,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(child: Text(context.l10n.noCompanyUsersFound));
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
            DataColumn(label: Text(l10n.companyMembersNameColumn)),
            DataColumn(label: Text(l10n.companyMembersPhoneColumn)),
            DataColumn(label: Text(l10n.companyMembersRoleColumn)),
            DataColumn(label: Text(l10n.companyMembersStatusColumn)),
            DataColumn(label: Text(l10n.companyMembersActionsColumn)),
          ],
          rows: users
              .map(
                (user) => DataRow(
                  cells: [
                    DataCell(Text(_displayName(context, user))),
                    DataCell(Text(_phone(context, user))),
                    DataCell(Text(user.role.localizedLabel(context))),
                    DataCell(Text(_statusLabel(context, user))),
                    DataCell(_actions(context, user)),
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
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  child: Text(
                    user.role.localizedLabel(context).substring(0, 1),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName(context, user),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(_phone(context, user)),
                      Text(
                        context.l10n.roleLine(
                          user.role.localizedLabel(context),
                        ),
                      ),
                      Text(
                        context.l10n.statusLine(_statusLabel(context, user)),
                      ),
                    ],
                  ),
                ),
                _actions(context, user),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actions(BuildContext context, CompanyUser user) {
    final actions = _availableActions(user);
    if (actions.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<_CompanyMemberAction>(
      enabled: !actionInProgress,
      icon: const Icon(AppIcons.moreActions),
      onSelected: (action) => _runAction(action, user),
      itemBuilder: (context) => actions
          .map(
            (action) => PopupMenuItem(
              value: action,
              child: Row(
                children: [
                  Icon(_actionIcon(action), size: AppSizes.iconSm),
                  const SizedBox(width: AppSpacing.sm),
                  Text(_actionLabel(context, action)),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  List<_CompanyMemberAction> _availableActions(CompanyUser user) {
    final actorRole = currentCompanyContext.role;
    final actions = <_CompanyMemberAction>[];

    final assignableRoles = CompanyInvitationPolicy.assignableRoles(actorRole);
    final canChangeRole = user.isActive &&
        assignableRoles.any(
          (newRole) => CompanyMembershipManagementPolicy.canChangeRole(
            actorRole: actorRole,
            targetRole: user.role,
            newRole: newRole,
          ),
        );
    if (canChangeRole) {
      actions.add(_CompanyMemberAction.changeRole);
    }

    final canChangeStatus =
        CompanyMembershipManagementPolicy.canChangeActiveStatus(
          actorRole: actorRole,
          targetRole: user.role,
        );
    if (canChangeStatus) {
      actions.add(
        user.isActive
            ? _CompanyMemberAction.deactivate
            : _CompanyMemberAction.reactivate,
      );
    }

    final canManageOwnership =
        CompanyMembershipManagementPolicy.canManageOwnership(actorRole) &&
        user.isActive &&
        currentUserId != null &&
        user.userId != currentUserId;
    if (canManageOwnership && user.role != CompanyRole.owner) {
      actions.add(_CompanyMemberAction.grantOwnership);
    }
    if (canManageOwnership) {
      actions.add(_CompanyMemberAction.transferOwnership);
    }

    return actions;
  }

  void _runAction(_CompanyMemberAction action, CompanyUser user) {
    switch (action) {
      case _CompanyMemberAction.changeRole:
        onChangeRole(user);
        break;
      case _CompanyMemberAction.deactivate:
        onDeactivate(user);
        break;
      case _CompanyMemberAction.reactivate:
        onReactivate(user);
        break;
      case _CompanyMemberAction.grantOwnership:
        onGrantOwnership(user);
        break;
      case _CompanyMemberAction.transferOwnership:
        onTransferOwnership(user);
        break;
    }
  }

  IconData _actionIcon(_CompanyMemberAction action) {
    return switch (action) {
      _CompanyMemberAction.changeRole => AppIcons.edit,
      _CompanyMemberAction.deactivate => AppIcons.deactivate,
      _CompanyMemberAction.reactivate => AppIcons.reactivate,
      _CompanyMemberAction.grantOwnership => AppIcons.ownership,
      _CompanyMemberAction.transferOwnership => AppIcons.transfer,
    };
  }

  String _actionLabel(BuildContext context, _CompanyMemberAction action) {
    final l10n = context.l10n;
    return switch (action) {
      _CompanyMemberAction.changeRole => l10n.companyMemberChangeRoleAction,
      _CompanyMemberAction.deactivate => l10n.companyMemberDeactivateAction,
      _CompanyMemberAction.reactivate => l10n.companyMemberReactivateAction,
      _CompanyMemberAction.grantOwnership => l10n.companyOwnershipGrantAction,
      _CompanyMemberAction.transferOwnership =>
        l10n.companyOwnershipTransferAction,
    };
  }

  String _displayName(BuildContext context, CompanyUser user) {
    final displayName = user.displayName?.trim();
    return displayName == null || displayName.isEmpty
        ? context.l10n.unknownUser
        : displayName;
  }

  String _phone(BuildContext context, CompanyUser user) {
    final phone = user.phone?.trim();
    return phone == null || phone.isEmpty
        ? context.l10n.profileDetailsNotSetYet
        : phone;
  }

  String _statusLabel(BuildContext context, CompanyUser user) {
    return user.isActive
        ? context.l10n.activeStatus
        : context.l10n.inactiveStatus;
  }
}
