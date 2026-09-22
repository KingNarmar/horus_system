import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/value_objects/trip_number.dart';
import 'package:horus_system/features/trips/presentation/widgets/trip_basic_info_section.dart';
import 'package:horus_system/features/trips/presentation/widgets/trip_card.dart';
import 'package:horus_system/features/trips/presentation/widgets/trips_table.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  group('Trip reference presentation', () {
    testWidgets('Trip card uses the canonical reference as its identity', (
      tester,
    ) async {
      await tester.pumpWidget(
        _localizedApp(
          TripCard(
            trip: _trip,
            financialConfiguration: null,
            canManageTrips: true,
            canUpdateTripStatus: true,
            canViewTripFinancials: false,
            isChanging: false,
            onViewDetails: (_) {},
            onEdit: (_) {},
            onUpdateStatus: (_) {},
          ),
        ),
      );

      expect(find.text('TRP-2026-000004'), findsOneWidget);
      expect(find.text('LO-999'), findsNothing);
    });

    testWidgets('Trips table labels and displays the canonical reference', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _localizedApp(
          TripsTable(
            trips: [_trip],
            financialConfiguration: null,
            canManageTrips: true,
            canUpdateTripStatus: true,
            canViewTripFinancials: false,
            isStatusChanging: (_) => false,
            onViewDetails: (_) {},
            onEdit: (_) {},
            onUpdateStatus: (_) {},
          ),
        ),
      );

      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.tripReferenceHeader), findsOneWidget);
      expect(find.text('TRP-2026-000004'), findsOneWidget);
      expect(find.text('LO-999'), findsOneWidget);
    });

    testWidgets('Trip details show a localized reference field in Arabic RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _localizedApp(
          TripBasicInfoSection(trip: _trip, financialConfiguration: null),
          locale: const Locale('ar'),
        ),
      );

      final l10n = AppLocalizationsAr();
      expect(find.text(l10n.tripReferenceHeader), findsOneWidget);
      expect(find.text('TRP-2026-000004'), findsOneWidget);

      final context = tester.element(find.byType(TripBasicInfoSection));
      expect(Directionality.of(context), TextDirection.rtl);
      expect(tester.takeException(), isNull);
    });
  });
}

final _trip = TripEntity(
  id: 'trip-1',
  companyId: 'company-1',
  tripNumber: TripNumber.tryParse('TRP-2026-000004')!,
  customerId: 'customer-1',
  routeId: 'route-1',
  status: TripStatus.created,
  loadingOrderNumber: 'LO-999',
  waybillNumber: 'WB-999',
  customerName: 'Mina',
  routeName: 'DUBAI -> SHARJAH',
);

Widget _localizedApp(Widget child, {Locale? locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}
