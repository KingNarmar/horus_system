import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_spacing.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/company/domain/entities/current_company_context.dart';
import '../../features/company/presentation/cubit/current_company_cubit.dart';
import '../../features/company/presentation/cubit/current_company_state.dart';
import '../../features/company/presentation/pages/company_onboarding_page.dart';

class AuthenticatedRouteGuard extends StatelessWidget {
  final Widget child;

  const AuthenticatedRouteGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.read<CurrentCompanyCubit>().clearCurrentCompanyContext();
        }
      },
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthAuthenticated) {
          return child;
        }

        return const LoginPage();
      },
    );
  }
}

class CompanyRequiredRouteGuard extends StatelessWidget {
  final Widget Function(CurrentCompanyContext currentCompanyContext) builder;

  const CompanyRequiredRouteGuard({required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    return AuthenticatedRouteGuard(
      child: _CompanyContextRouteGuard(builder: builder),
    );
  }
}

class _CompanyContextRouteGuard extends StatefulWidget {
  final Widget Function(CurrentCompanyContext currentCompanyContext) builder;

  const _CompanyContextRouteGuard({required this.builder});

  @override
  State<_CompanyContextRouteGuard> createState() =>
      _CompanyContextRouteGuardState();
}

class _CompanyContextRouteGuardState extends State<_CompanyContextRouteGuard> {
  @override
  void initState() {
    super.initState();

    final currentState = context.read<CurrentCompanyCubit>().state;

    if (currentState is CurrentCompanyInitial) {
      context.read<CurrentCompanyCubit>().loadCurrentCompanyContext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrentCompanyCubit, CurrentCompanyState>(
      builder: (context, state) {
        if (state is CurrentCompanyInitial || state is CurrentCompanyLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CurrentCompanyLoaded) {
          return widget.builder(state.context);
        }

        if (state is CurrentCompanyEmpty) {
          return const CompanyOnboardingPage();
        }

        if (state is CurrentCompanyFailure) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(state.failure.message, textAlign: TextAlign.center),
              ),
            ),
          );
        }

        return const CompanyOnboardingPage();
      },
    );
  }
}
