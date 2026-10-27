import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'company_scoped_cubit_boundary.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/company/domain/entities/current_company_context.dart';
import '../../features/company/presentation/cubit/company_switcher_cubit.dart';
import '../../features/company/presentation/widgets/company_context_access_view.dart';

class AuthenticatedRouteGuard extends StatelessWidget {
  final Widget child;

  const AuthenticatedRouteGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
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
  final CompanySwitcherCubit Function()? createCompanySwitcherCubit;

  const CompanyRequiredRouteGuard({
    required this.builder,
    this.createCompanySwitcherCubit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AuthenticatedRouteGuard(
      child: CompanyContextAccessView(
        createCompanySwitcherCubit: createCompanySwitcherCubit,
        builder: (companyContext) =>
            CompanyScopedCubitBoundary(child: builder(companyContext)),
      ),
    );
  }
}
