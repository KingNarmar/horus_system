import 'package:flutter/material.dart';

import '../../../app_shell/presentation/pages/app_shell_page.dart';
import '../widgets/company_context_access_view.dart';

/// Root company entry. Session ownership belongs to the app-level boundary.
final class CurrentCompanyGate extends StatelessWidget {
  const CurrentCompanyGate({super.key});

  @override
  Widget build(BuildContext context) {
    return CompanyContextAccessView(
      builder: (companyContext) =>
          AppShellPage(currentCompanyContext: companyContext),
    );
  }
}
