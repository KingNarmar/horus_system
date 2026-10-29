import 'package:flutter/material.dart';

import '../../../../app/routing/company_scoped_cubit_boundary.dart';
import '../../../../core/di/app_dependencies.dart';

import '../../../app_shell/presentation/pages/app_shell_page.dart';
import '../widgets/company_context_access_view.dart';

/// Root company entry. Session ownership belongs to the app-level boundary.
final class CurrentCompanyGate extends StatelessWidget {
  const CurrentCompanyGate({super.key});

  @override
  Widget build(BuildContext context) {
    return CompanyContextAccessView(
      createCompanySwitcherCubit: AppDependencies.createCompanySwitcherCubit,
      builder: (companyContext) => CompanyScopedCubitBoundary(
        child: AppShellPage(
          currentCompanyContext: companyContext,
          createCompanySwitcherCubit:
              AppDependencies.createCompanySwitcherCubit,
        ),
      ),
    );
  }
}
