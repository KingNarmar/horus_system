import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/routes/domain/entities/route_entity.dart';
import 'package:horus_system/features/routes/presentation/widgets/routes_list.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('narrow route cards expose labeled lifecycle actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RoutesList(
            routes: const [
              RouteEntity(
                id: 'route-1',
                companyId: 'company-1',
                loadingLocation: 'Dubai',
                unloadingLocation: 'Abu Dhabi',
                isActive: true,
              ),
            ],
            financialConfiguration: null,
            canManageRoutes: true,
            isActiveStateChanging: (_) => false,
            onViewDetails: (_) {},
            onEdit: (_) {},
            onDeactivate: (_) {},
            onReactivate: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'View details'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Edit'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Deactivate'), findsOneWidget);
    expect(find.textContaining('Not available'), findsWidgets);
  });
}
