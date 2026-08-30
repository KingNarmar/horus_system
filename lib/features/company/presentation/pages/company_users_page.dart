import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart'
    show AppLocalizationsX;
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/company_invitation.dart';
import '../../domain/entities/company_role.dart';
import '../../domain/entities/company_user.dart';
import '../../domain/entities/current_company_context.dart';
import '../../domain/policies/company_invitation_policy.dart';
import '../../domain/policies/company_permission_policy.dart';
import '../cubit/company_invitations_cubit.dart';
import '../cubit/company_invitations_state.dart';
import '../cubit/company_member_actions_cubit.dart';
import '../cubit/company_member_actions_state.dart';
import '../cubit/company_users_cubit.dart';
import '../cubit/company_users_state.dart';
import '../cubit/current_company_cubit.dart';
import '../cubit/current_company_state.dart';
import '../extensions/company_failure_localization.dart';
import '../helpers/company_users_action_dialogs.dart';
import '../widgets/company_invitations_view.dart';
import '../widgets/company_members_view.dart';

class CompanyUsersPage extends StatefulWidget {
  const CompanyUsersPage({super.key});

  @override
  State<CompanyUsersPage> createState() => _CompanyUsersPageState();
}

class _CompanyUsersPageState extends State<CompanyUsersPage> {
  String? _loadedCompanyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<CurrentCompanyCubit>().state;
    if (state is CurrentCompanyLoaded) {
      _loadCompanyData(state.context);
    }
  }

  void _loadCompanyData(CurrentCompanyContext currentCompanyContext) {
    if (_loadedCompanyId == currentCompanyContext.companyId) return;
    _loadedCompanyId = currentCompanyContext.companyId;

    context.read<CompanyUsersCubit>().loadCompanyUsers(
      currentCompanyContext: currentCompanyContext,
    );

    if (CompanyInvitationPolicy.canViewInvitations(
      currentCompanyContext.role,
    )) {
      context.read<CompanyInvitationsCubit>().load(currentCompanyContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentCompanyState = context.watch<CurrentCompanyCubit>().state;

    if (currentCompanyState is CurrentCompanyInitial ||
        currentCompanyState is CurrentCompanyLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentCompanyState is CurrentCompanyFailure) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n.localizedErrorMessage(currentCompanyState.failure),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (currentCompanyState is! CurrentCompanyLoaded) {
      return Scaffold(
        body: Center(child: Text(l10n.currentCompanyContextRequired)),
      );
    }

    final currentCompanyContext = currentCompanyState.context;
    if (!CompanyPermissionPolicy.canViewCompanyUsers(
      currentCompanyContext.role,
    )) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.companyUsersTitle)),
        body: Center(child: Text(l10n.noPermissionManageUsers)),
      );
    }

    final canViewInvitations = CompanyInvitationPolicy.canViewInvitations(
      currentCompanyContext.role,
    );
    final assignableRoles = CompanyInvitationPolicy.assignableRoles(
      currentCompanyContext.role,
    );
    final canInvite = assignableRoles.isNotEmpty;
    final isWide =
        MediaQuery.sizeOf(context).width >= AppSizes.dataTableBreakpoint;
    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.id
        : null;

    return DefaultTabController(
      length: canViewInvitations ? 2 : 1,
      child: MultiBlocListener(
        listeners: [
          BlocListener<CurrentCompanyCubit, CurrentCompanyState>(
            listenWhen: (previous, current) {
              final previousId = previous is CurrentCompanyLoaded
                  ? previous.context.companyId
                  : null;
              final currentId = current is CurrentCompanyLoaded
                  ? current.context.companyId
                  : null;
              return currentId != null && currentId != previousId;
            },
            listener: (context, state) {
              if (state is CurrentCompanyLoaded) {
                _loadedCompanyId = null;
                _loadCompanyData(state.context);
              }
            },
          ),
          BlocListener<CompanyMemberActionsCubit, CompanyMemberActionsState>(
            listener: (context, state) {
              if (state.companyId != currentCompanyContext.companyId) return;

              if (state is CompanyMemberActionFailed) {
                _showFailure(state.failure);
              } else if (state is CompanyMemberActionSucceeded) {
                _handleMemberActionSuccess(currentCompanyContext.companyId);
              }
            },
          ),
          BlocListener<CompanyInvitationsCubit, CompanyInvitationsState>(
            listenWhen: (previous, current) {
              if (current.companyId != currentCompanyContext.companyId) {
                return false;
              }
              return current is CompanyInvitationsFailure ||
                  (previous is CompanyInvitationsCommandInProgress &&
                      current is CompanyInvitationsLoaded);
            },
            listener: (context, state) {
              if (state is CompanyInvitationsFailure) {
                _showFailure(state.failure);
              } else if (state is CompanyInvitationsLoaded) {
                _showSuccess(context.l10n.companyInvitationActionSucceeded);
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.companyUsersTitle),
            actions: [
              if (canInvite && isWide)
                TextButton.icon(
                  onPressed: () => _invite(
                    currentCompanyContext,
                    assignableRoles,
                  ),
                  icon: const Icon(AppIcons.userAdd),
                  label: Text(l10n.inviteButton),
                ),
              const SizedBox(width: AppSpacing.sm),
            ],
            bottom: TabBar(
              tabs: [
                Tab(
                  icon: const Icon(AppIcons.userAdmin),
                  text: l10n.companyMembersTab,
                ),
                if (canViewInvitations)
                  Tab(
                    icon: const Icon(AppIcons.invitations),
                    text: l10n.companyInvitationsTab,
                  ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _membersTab(currentCompanyContext, currentUserId),
              if (canViewInvitations)
                _invitationsTab(currentCompanyContext),
            ],
          ),
          floatingActionButton: canInvite && !isWide
              ? FloatingActionButton.extended(
                  onPressed: () => _invite(
                    currentCompanyContext,
                    assignableRoles,
                  ),
                  icon: const Icon(AppIcons.userAdd),
                  label: Text(l10n.inviteButton),
                )
              : null,
        ),
      ),
    );
  }

  Widget _membersTab(
    CurrentCompanyContext currentCompanyContext,
    String? currentUserId,
  ) {
    return BlocBuilder<CompanyUsersCubit, CompanyUsersState>(
      builder: (context, state) {
        if (state is CompanyUsersInitial || state is CompanyUsersLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CompanyUsersFailure) {
          return _LoadFailureView(
            message: context.l10n.localizedErrorMessage(state.failure),
            onRetry: () => context.read<CompanyUsersCubit>().loadCompanyUsers(
              currentCompanyContext: currentCompanyContext,
            ),
          );
        }

        if (state is CompanyUsersLoaded) {
          final actionInProgress =
              context.watch<CompanyMemberActionsCubit>().state
                  is CompanyMemberActionInProgress;
          return CompanyMembersView(
            users: state.users,
            currentCompanyContext: currentCompanyContext,
            currentUserId: currentUserId,
            actionInProgress: actionInProgress,
            onChangeRole: (user) => _changeRole(currentCompanyContext, user),
            onDeactivate: (user) => _deactivate(currentCompanyContext, user),
            onReactivate: (user) => _reactivate(currentCompanyContext, user),
            onGrantOwnership: (user) =>
                _grantOwnership(currentCompanyContext, user),
            onTransferOwnership: (user) =>
                _transferOwnership(currentCompanyContext, user),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _invitationsTab(CurrentCompanyContext currentCompanyContext) {
    return BlocBuilder<CompanyInvitationsCubit, CompanyInvitationsState>(
      builder: (context, state) {
        if (state is CompanyInvitationsInitial ||
            state is CompanyInvitationsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CompanyInvitationsLoaded) {
          return _invitationsView(
            currentCompanyContext,
            state.invitations,
            actionInProgress: false,
          );
        }

        if (state is CompanyInvitationsCommandInProgress) {
          return Column(
            children: [
              const LinearProgressIndicator(),
              Expanded(
                child: _invitationsView(
                  currentCompanyContext,
                  state.invitations,
                  actionInProgress: true,
                ),
              ),
            ],
          );
        }

        if (state is CompanyInvitationsFailure) {
          if (state.invitations.isNotEmpty) {
            return _invitationsView(
              currentCompanyContext,
              state.invitations,
              actionInProgress: false,
            );
          }

          return _LoadFailureView(
            message: context.l10n.localizedErrorMessage(state.failure),
            onRetry: () => context.read<CompanyInvitationsCubit>().load(
              currentCompanyContext,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _invitationsView(
    CurrentCompanyContext currentCompanyContext,
    List<CompanyInvitation> invitations, {
    required bool actionInProgress,
  }) {
    return CompanyInvitationsView(
      invitations: invitations,
      actionInProgress: actionInProgress,
      onResend: (invitation) =>
          _resendInvitation(currentCompanyContext, invitation),
      onRevoke: (invitation) =>
          _revokeInvitation(currentCompanyContext, invitation),
    );
  }

  Future<void> _invite(
    CurrentCompanyContext currentCompanyContext,
    List<CompanyRole> assignableRoles,
  ) async {
    final input = await CompanyUsersActionDialogs.showInvite(
      context,
      assignableRoles: assignableRoles,
    );
    if (!mounted || input == null) return;

    await context.read<CompanyInvitationsCubit>().send(
      currentCompanyContext: currentCompanyContext,
      email: input.email,
      role: input.role,
    );
  }

  Future<void> _changeRole(
    CurrentCompanyContext currentCompanyContext,
    CompanyUser user,
  ) async {
    final newRole = await CompanyUsersActionDialogs.showRoleChange(
      context,
      user: user,
      availableRoles: CompanyInvitationPolicy.assignableRoles(
        currentCompanyContext.role,
      ),
    );
    if (!mounted || newRole == null) return;

    await context.read<CompanyMemberActionsCubit>().changeRole(
      currentCompanyContext: currentCompanyContext,
      membershipId: user.id,
      currentRole: user.role,
      newRole: newRole,
    );
  }

  Future<void> _deactivate(
    CurrentCompanyContext currentCompanyContext,
    CompanyUser user,
  ) async {
    final confirmed = await CompanyUsersActionDialogs.confirmDeactivate(
      context,
      user: user,
    );
    if (!mounted || !confirmed) return;

    await context.read<CompanyMemberActionsCubit>().deactivate(
      currentCompanyContext: currentCompanyContext,
      membershipId: user.id,
      targetRole: user.role,
    );
  }

  Future<void> _reactivate(
    CurrentCompanyContext currentCompanyContext,
    CompanyUser user,
  ) async {
    final confirmed = await CompanyUsersActionDialogs.confirmReactivate(
      context,
      user: user,
    );
    if (!mounted || !confirmed) return;

    await context.read<CompanyMemberActionsCubit>().reactivate(
      currentCompanyContext: currentCompanyContext,
      membershipId: user.id,
      targetRole: user.role,
    );
  }

  Future<void> _grantOwnership(
    CurrentCompanyContext currentCompanyContext,
    CompanyUser user,
  ) async {
    final confirmed = await CompanyUsersActionDialogs.confirmGrantOwnership(
      context,
      user: user,
    );
    if (!mounted || !confirmed) return;

    await context.read<CompanyMemberActionsCubit>().grantOwnership(
      currentCompanyContext: currentCompanyContext,
      membershipId: user.id,
    );
  }

  Future<void> _transferOwnership(
    CurrentCompanyContext currentCompanyContext,
    CompanyUser user,
  ) async {
    final sourceNewRole = await CompanyUsersActionDialogs.showOwnershipTransfer(
      context,
      sourceRoles: CompanyInvitationPolicy.assignableRoles(
        currentCompanyContext.role,
      ),
    );
    if (!mounted || sourceNewRole == null) return;

    await context.read<CompanyMemberActionsCubit>().transferOwnership(
      currentCompanyContext: currentCompanyContext,
      targetMembershipId: user.id,
      sourceNewRole: sourceNewRole,
    );
  }

  Future<void> _resendInvitation(
    CurrentCompanyContext currentCompanyContext,
    CompanyInvitation invitation,
  ) async {
    final confirmed = await CompanyUsersActionDialogs.confirmResendInvitation(
      context,
      invitation: invitation,
    );
    if (!mounted || !confirmed) return;

    await context.read<CompanyInvitationsCubit>().resend(
      currentCompanyContext: currentCompanyContext,
      invitationId: invitation.id,
    );
  }

  Future<void> _revokeInvitation(
    CurrentCompanyContext currentCompanyContext,
    CompanyInvitation invitation,
  ) async {
    final confirmed = await CompanyUsersActionDialogs.confirmRevokeInvitation(
      context,
      invitation: invitation,
    );
    if (!mounted || !confirmed) return;

    await context.read<CompanyInvitationsCubit>().revoke(
      currentCompanyContext: currentCompanyContext,
      invitationId: invitation.id,
    );
  }

  Future<void> _handleMemberActionSuccess(String companyId) async {
    _showSuccess(context.l10n.companyMemberActionSucceeded);

    final currentCompanyCubit = context.read<CurrentCompanyCubit>();
    await currentCompanyCubit.refreshAndSelectCompany(companyId);
    if (!mounted) return;

    final state = currentCompanyCubit.state;
    if (state is CurrentCompanyLoaded &&
        state.context.companyId == companyId &&
        CompanyPermissionPolicy.canViewCompanyUsers(state.context.role)) {
      await context.read<CompanyUsersCubit>().loadCompanyUsers(
        currentCompanyContext: state.context,
      );
    }
  }

  void _showFailure(Failure failure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.localizedErrorMessage(failure))),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _LoadFailureView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadFailureView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(AppIcons.resend),
              label: Text(context.l10n.retryButton),
            ),
          ],
        ),
      ),
    );
  }
}
