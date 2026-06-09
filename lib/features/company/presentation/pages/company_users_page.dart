import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/company_role.dart';
import '../../domain/entities/company_user.dart';
import '../../domain/entities/current_company_context.dart';
import '../../domain/policies/company_permission_policy.dart';
import '../cubit/company_users_cubit.dart';
import '../cubit/company_users_state.dart';
import '../cubit/current_company_cubit.dart';
import '../cubit/current_company_state.dart';

class CompanyUsersPage extends StatefulWidget {
  const CompanyUsersPage({super.key});

  @override
  State<CompanyUsersPage> createState() => _CompanyUsersPageState();
}

class _CompanyUsersPageState extends State<CompanyUsersPage> {
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoad) {
      return;
    }

    _didLoad = true;

    final currentCompanyState = context.read<CurrentCompanyCubit>().state;

    if (currentCompanyState is CurrentCompanyLoaded) {
      context.read<CompanyUsersCubit>().loadCompanyUsers(
            currentCompanyContext: currentCompanyState.context,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCompanyState = context.watch<CurrentCompanyCubit>().state;

    if (currentCompanyState is! CurrentCompanyLoaded) {
      return const Scaffold(
        body: Center(child: Text('Current company context is required.')),
      );
    }

    final currentCompanyContext = currentCompanyState.context;
    final permissions = CompanyPermissionPolicy.permissionsFor(
      currentCompanyContext.role,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Users'),
        actions: [
          if (permissions.canInviteCompanyUsers)
            TextButton.icon(
              onPressed: () => _showInvitePlaceholder(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Invite'),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: BlocBuilder<CompanyUsersCubit, CompanyUsersState>(
        builder: (context, state) {
          if (state is CompanyUsersInitial || state is CompanyUsersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CompanyUsersFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  state.failure.message,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (state is CompanyUsersLoaded) {
            if (state.users.isEmpty) {
              return const Center(child: Text('No company users found.'));
            }

            return _CompanyUsersList(
              users: state.users,
              currentCompanyContext: currentCompanyContext,
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: permissions.canInviteCompanyUsers
          ? FloatingActionButton.extended(
              onPressed: () => _showInvitePlaceholder(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Invite'),
            )
          : null,
    );
  }

  void _showInvitePlaceholder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite flow will be implemented in a later issue.'),
      ),
    );
  }
}

class _CompanyUsersList extends StatelessWidget {
  final List<CompanyUser> users;
  final CurrentCompanyContext currentCompanyContext;

  const _CompanyUsersList({
    required this.users,
    required this.currentCompanyContext,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemBuilder: (context, index) {
        final user = users[index];

        return _CompanyUserTile(
          user: user,
          isCurrentUserRoleOwner:
              currentCompanyContext.role == CompanyRole.owner,
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemCount: users.length,
    );
  }
}

class _CompanyUserTile extends StatelessWidget {
  final CompanyUser user;
  final bool isCurrentUserRoleOwner;

  const _CompanyUserTile({
    required this.user,
    required this.isCurrentUserRoleOwner,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusText = user.isActive ? 'Active' : 'Inactive';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.role.label.characters.first),
        ),
        title: Text(user.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text('Role: ${user.role.label}'),
            Text('Status: $statusText'),
            Text(
              'User ID: ${user.userId}',
              style: textTheme.bodySmall,
            ),
          ],
        ),
        trailing: isCurrentUserRoleOwner
            ? const Icon(Icons.admin_panel_settings_outlined)
            : null,
      ),
    );
  }
}
