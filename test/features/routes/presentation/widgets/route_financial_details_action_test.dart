import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/routes/domain/entities/route_entity.dart';
import 'package:horus_system/features/routes/presentation/cubit/routes_state.dart';
import 'package:horus_system/features/routes/presentation/widgets/route_activity_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  for (final role in [
    CompanyRole.owner,
    CompanyRole.admin,
    CompanyRole.accountant,
  ]) {
    testWidgets('finance actor ${role.name} can access only Route rate action', (
      tester,
    ) async {
      var pressed = false;
      await tester.pumpWidget(_app(role: role, onRateEdit: (_) => pressed = true));
      final rateButton = find.byType(OutlinedButton);
      expect(rateButton, findsOneWidget);
      await tester.tap(rateButton);
      expect(pressed, isTrue);
    });
  }

  for (final role in [
    CompanyRole.operations,
    CompanyRole.viewer,
    CompanyRole.driver,
  ]) {
    testWidgets('no financial Route action for ${role.name}', (tester) async {
      await tester.pumpWidget(
        _app(
          role: role,
          onRateEdit: (_) => fail('Unauthorized financial action visible'),
        ),
      );
      expect(find.byType(OutlinedButton), findsNothing);
    });
  }
}

Widget _app({
  required CompanyRole role,
  required ValueChanged<RouteEntity> onRateEdit,
}) {
  final context = CurrentCompanyContext(
    company: const Company(
      id: 'company-1',
      name: 'Company',
      baseCurrencyCode: 'AED',
      baseCurrencyFractionDigits: 2,
    ),
    role: role,
  );
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: RouteDetailsDialog(
        route: _route,
        state: RoutesLoaded(
          currentCompanyContext: context,
          allRoutes: [_route],
          canManageRoutes: false,
        ),
        onEditDefaultRate: onRateEdit,
      ),
    ),
  );
}

const _route = RouteEntity(
  id: 'route-1',
  companyId: 'company-1',
  loadingLocation: 'Dubai',
  unloadingLocation: 'Sharjah',
  isActive: true,
);
