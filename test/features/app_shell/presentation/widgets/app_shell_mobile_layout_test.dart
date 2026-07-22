import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/app/routing/app_routes.dart';
import 'package:horus_system/features/app_shell/presentation/models/app_shell_destination.dart';
import 'package:horus_system/features/app_shell/presentation/widgets/app_shell_mobile_layout.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';

void main() {
  group('App Shell driver settlements integration', () {
    test('registers driver settlements as a company-scoped route', () {
      expect(
        AppRoutes.companyRequiredRoutes,
        contains(AppRoutes.driverSettlements),
      );

      final destinations = appShellDestinations
          .where(
            (destination) =>
                destination.module == AppShellModule.driverSettlements,
          )
          .toList();

      expect(destinations, hasLength(1));
    });

    test('resolves mobile primary navigation by module instead of indexes', () {
      final dashboardIndex = appShellDestinations.indexWhere(
        (destination) => destination.module == AppShellModule.dashboard,
      );

      final layout = AppShellMobileLayout(
        contextData: _companyContext,
        selected: appShellDestinations[dashboardIndex],
        selectedIndex: dashboardIndex,
        onSelect: (_) {},
        onLogout: () {},
      );

      final primaryIndexes = layout.primaryIndexes;

      expect(
        primaryIndexes,
        hasLength(AppShellMobileLayout.primaryModules.length),
      );
      expect(primaryIndexes, everyElement(greaterThanOrEqualTo(0)));
      expect(
        primaryIndexes.map((index) => appShellDestinations[index].module),
        AppShellMobileLayout.primaryModules,
      );
      expect(layout.navIndex, 0);
    });

    test('places driver settlements under mobile More navigation', () {
      final settlementIndex = appShellDestinations.indexWhere(
        (destination) => destination.module == AppShellModule.driverSettlements,
      );

      final layout = AppShellMobileLayout(
        contextData: _companyContext,
        selected: appShellDestinations[settlementIndex],
        selectedIndex: settlementIndex,
        onSelect: (_) {},
        onLogout: () {},
      );

      expect(settlementIndex, greaterThanOrEqualTo(0));
      expect(layout.navIndex, AppShellMobileLayout.primaryModules.length);
    });
  });
}

const _companyContext = CurrentCompanyContext(
  company: Company(id: 'company-1', name: 'Test Company'),
  role: CompanyRole.owner,
);
