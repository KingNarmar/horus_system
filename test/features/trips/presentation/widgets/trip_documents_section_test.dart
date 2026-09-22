import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document_kind.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/value_objects/trip_number.dart';
import 'package:horus_system/features/trips/presentation/cubit/trips_state.dart';
import 'package:horus_system/features/trips/presentation/widgets/trip_documents_section.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  group('TripDocumentsSection', () {
    testWidgets('shows evidence readiness and full manager lifecycle actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _localizedApp(TripDocumentsSection(trip: _trip, state: _loadedState())),
      );

      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.tripDocumentEvidenceReady), findsOneWidget);
      expect(find.text('waybill.pdf'), findsOneWidget);
      expect(find.byTooltip(l10n.tripDocumentViewButton), findsOneWidget);
      expect(find.byTooltip(l10n.tripDocumentDownloadButton), findsOneWidget);
      expect(find.byTooltip(l10n.tripDocumentReplaceButton), findsOneWidget);
      expect(find.byTooltip(l10n.tripDocumentRemoveButton), findsOneWidget);
      expect(find.text(l10n.tripDocumentUploadButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is usable on narrow Arabic RTL layout', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _localizedApp(
          TripDocumentsSection(trip: _trip, state: _loadedState()),
          locale: const Locale('ar'),
        ),
      );

      final l10n = AppLocalizationsAr();
      expect(find.text(l10n.tripDocumentEvidenceReady), findsOneWidget);
      expect(find.byTooltip(l10n.tripDocumentDownloadButton), findsOneWidget);

      final context = tester.element(find.byType(TripDocumentsSection));
      expect(Directionality.of(context), TextDirection.rtl);
      expect(tester.takeException(), isNull);
    });

    testWidgets('viewer sees documents without mutation actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _localizedApp(
          TripDocumentsSection(
            trip: _trip,
            state: _loadedState(canManageDocuments: false),
          ),
        ),
      );

      final l10n = AppLocalizationsEn();
      expect(find.byTooltip(l10n.tripDocumentViewButton), findsOneWidget);
      expect(find.byTooltip(l10n.tripDocumentDownloadButton), findsOneWidget);
      expect(find.byTooltip(l10n.tripDocumentReplaceButton), findsNothing);
      expect(find.byTooltip(l10n.tripDocumentRemoveButton), findsNothing);
      expect(find.text(l10n.tripDocumentUploadButton), findsNothing);
    });
  });
}

const _company = Company(id: 'company-1', name: 'Company');
const _context = CurrentCompanyContext(
  company: _company,
  role: CompanyRole.operations,
);
final _trip = TripEntity(
  id: 'trip-1',
  companyId: 'company-1',
  tripNumber: TripNumber.tryParse('TRP-2026-000001')!,
  customerId: 'customer-1',
  routeId: 'route-1',
  status: TripStatus.delivered,
);

final _waybill = TripDocument(
  id: 'document-1',
  companyId: 'company-1',
  tripId: 'trip-1',
  kind: TripDocumentKind.waybill,
  originalFileName: 'waybill.pdf',
  mimeType: 'application/pdf',
  sizeBytes: 1024,
  uploadedAt: DateTime.utc(2026, 9, 18),
);

TripsLoaded _loadedState({bool canManageDocuments = true}) {
  return TripsLoaded(
    currentCompanyContext: _context,
    allTrips: [_trip],
    canManageTrips: true,
    canUpdateTripStatus: true,
    canManageTripDocuments: canManageDocuments,
    canViewTripFinancials: true,
    canManageTripExpenses: true,
    selectedTrip: _trip,
    selectedTripDocuments: [_waybill],
    hasRequiredTripEvidence: true,
  );
}

Widget _localizedApp(Widget home, {Locale? locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: home),
  );
}
