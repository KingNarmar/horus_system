import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_form_lookups.dart';
import 'package:horus_system/features/trips/domain/entities/trip_lookup_option.dart';
import 'package:horus_system/features/trips/domain/entities/trip_route_lookup_option.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/failures/trip_failure_codes.dart';
import 'package:horus_system/features/trips/domain/value_objects/trip_number.dart';
import 'package:horus_system/features/trips/presentation/models/trip_mutation_result.dart';
import 'package:horus_system/features/trips/presentation/widgets/trip_form_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets(
      'failed Trip save reveals localized error and keeps draft ($language)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => TripFormDialog(
                      title: 'Edit trip',
                      trip: _trip,
                      lookups: _lookups,
                      financialConfiguration: null,
                      onSubmit: (_) async => const TripMutationFailed(
                        ConflictFailure(
                          code: TripFailureCodes.concurrentModification,
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final localization = AppLocalizations.of(
          tester.element(find.byType(TripFormDialog)),
        );
        final formScroll = tester
            .widget<SingleChildScrollView>(
              find.ancestor(
                of: find.byType(Form),
                matching: find.byType(SingleChildScrollView),
              ),
            )
            .controller!;

        final notesField = find.byType(TextFormField).last;
        await tester.ensureVisible(notesField);
        await tester.pumpAndSettle();
        await tester.enterText(notesField, 'Keep this unsaved draft');
        await tester.pumpAndSettle();
        expect(formScroll.offset, greaterThan(0));

        await tester.tap(find.text(localization.saveButton));
        await tester.pumpAndSettle();

        final error = find.text(localization.tripConcurrentModificationFailure);
        expect(error, findsOneWidget);
        expect(formScroll.offset, formScroll.position.minScrollExtent);
        expect(find.byType(TripFormDialog), findsOneWidget);
        expect(
          tester.widget<TextFormField>(notesField).controller!.text,
          'Keep this unsaved draft',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

final _trip = TripEntity(
  id: 'trip-1',
  companyId: 'company-1',
  tripNumber: TripNumber.tryParse('TRP-2026-000001')!,
  customerId: 'customer-1',
  routeId: 'route-1',
  status: TripStatus.created,
);

const _lookups = TripFormLookups(
  customers: [TripLookupOption(id: 'customer-1', label: 'Customer One')],
  routes: [TripRouteLookupOption(id: 'route-1', label: 'Route One')],
  drivers: [],
  tractorHeads: [],
  trailers: [],
);
