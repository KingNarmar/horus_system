import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/app_shell/presentation/models/app_shell_destination.dart';
import 'package:horus_system/features/app_shell/presentation/models/finance_workspace_section.dart';
import 'package:horus_system/features/app_shell/presentation/widgets/app_shell_mobile_layout.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';

void main() {
  group('App Shell mobile navigation', () {
    test('resolves primary navigation from the filtered destination list', () {
      final destinations = appShellDestinationsForRole(_companyContext.role);
      final dashboardIndex = destinations.indexWhere(
        (destination) => destination.module == AppShellModule.dashboard,
      );

      final layout = AppShellMobileLayout(
        contextData: _companyContext,
        currentUser: null,
        destinations: destinations,
        selected: destinations[dashboardIndex],
        selectedIndex: dashboardIndex,
        selectedFinanceSection: FinanceWorkspaceSection.driverFinance,
        onSelect: (_) {},
        onFinanceSectionSelected: (_) {},
        onLogout: () {},
      );

      final primaryIndexes = layout.primaryIndexes;

      expect(
        primaryIndexes,
        hasLength(AppShellMobileLayout.primaryModules.length),
      );
      expect(primaryIndexes, everyElement(greaterThanOrEqualTo(0)));
      expect(
        primaryIndexes.map((index) => destinations[index].module),
        AppShellMobileLayout.primaryModules,
      );
      expect(layout.navIndex, 0);
    });

    test('places Finance under mobile More navigation', () {
      final destinations = appShellDestinationsForRole(_companyContext.role);
      final financeIndex = destinations.indexWhere(
        (destination) => destination.module == AppShellModule.finance,
      );

      final layout = AppShellMobileLayout(
        contextData: _companyContext,
        currentUser: null,
        destinations: destinations,
        selected: destinations[financeIndex],
        selectedIndex: financeIndex,
        selectedFinanceSection: FinanceWorkspaceSection.driverFinance,
        onSelect: (_) {},
        onFinanceSectionSelected: (_) {},
        onLogout: () {},
      );

      expect(financeIndex, greaterThanOrEqualTo(0));
      expect(layout.navIndex, AppShellMobileLayout.primaryModules.length);
    });
  });
}

const _companyContext = CurrentCompanyContext(
  company: Company(id: 'company-1', name: 'Test Company'),
  role: CompanyRole.owner,
);
