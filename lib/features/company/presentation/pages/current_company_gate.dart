import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/company_role.dart';
import '../../domain/entities/current_company_context.dart';
import '../../domain/policies/company_permission_policy.dart';
import '../cubit/current_company_cubit.dart';
import '../cubit/current_company_state.dart';
import 'company_onboarding_page.dart';
import 'company_users_page.dart';

class CurrentCompanyGate extends StatefulWidget {
  const CurrentCompanyGate({super.key});

  @override
  State<CurrentCompanyGate> createState() => _CurrentCompanyGateState();
}

class _CurrentCompanyGateState extends State<CurrentCompanyGate> {
  @override
  void initState() {
    super.initState();
    context.read<CurrentCompanyCubit>().loadCurrentCompanyContext();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrentCompanyCubit, CurrentCompanyState>(
      builder: (context, state) {
        if (state is CurrentCompanyLoading ||
            state is CurrentCompanyInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CurrentCompanyEmpty) {
          return const CompanyOnboardingPage();
        }

        if (state is CurrentCompanyLoaded) {
          return _CurrentCompanyLoadedView(
            currentCompanyContext: state.context,
          );
        }

        if (state is CurrentCompanyFailure) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  state.failure.message,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return const CompanyOnboardingPage();
      },
    );
  }
}

class _CurrentCompanyLoadedView extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;

  const _CurrentCompanyLoadedView({required this.currentCompanyContext});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final permissions = CompanyPermissionPolicy.permissionsFor(
      currentCompanyContext.role,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('H.O.R.U.S System'),
        actions: [
          TextButton.icon(
            onPressed: () => context.read<AuthCubit>().logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Company context loaded',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                currentCompanyContext.company.name,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your role: ${currentCompanyContext.role.label}',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Next step: responsive app shell and protected business modules.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (permissions.canViewCompanyUsers) ...[
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CompanyUsersPage(),
                    ),
                  ),
                  icon: const Icon(Icons.group_outlined),
                  label: const Text('Manage Users'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              OutlinedButton.icon(
                onPressed: () => context.read<AuthCubit>().logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
