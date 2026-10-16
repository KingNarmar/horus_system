import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_form_lookups.dart';
import 'package:horus_system/features/trips/domain/entities/trip_lookup_option.dart';
import 'package:horus_system/features/trips/domain/entities/trip_route_lookup_option.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/value_objects/trip_number.dart';
import 'package:horus_system/features/trips/presentation/models/trip_mutation_result.dart';
import 'package:horus_system/features/trips/presentation/widgets/trip_business_date_time_field.dart';
import 'package:horus_system/features/trips/presentation/widgets/trip_form_dialog.dart';
import 'package:horus_system/features/trips/presentation/widgets/trip_status_update_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  group('PC-10 Trip operational widgets', () {
    testWidgets('date-time field is picker-based and not free-typed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _localizedApp(
          Scaffold(
            body: TripBusinessDateTimeField(
              label: 'Scheduled loading',
              value: null,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(EditableText), findsNothing);

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);

      final dialog = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(dialog.firstDate.year, BusinessDate.minYear);
      expect(dialog.lastDate.year, BusinessDate.maxYear);
    });

    testWidgets('date-time field can clear an existing value', (tester) async {
      BusinessLocalDateTime? changedValue = BusinessLocalDateTime(
        year: 2026,
        month: 9,
        day: 18,
        hour: 10,
        minute: 30,
      );

      await tester.pumpWidget(
        _localizedApp(
          Scaffold(
            body: TripBusinessDateTimeField(
              label: 'Scheduled loading',
              value: changedValue,
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      final clearButton = find.byType(IconButton);
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pump();

      expect(changedValue, isNull);
    });

    testWidgets(
      'trip form dropdowns do not overflow on narrow Arabic RTL layouts',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _dialogLauncher(
            locale: const Locale('ar'),
            builder: (_) => TripFormDialog(
              title: 'تعديل رحلة',
              trip: _longLabelTrip,
              lookups: _longLabelLookups,
              financialConfiguration: null,
              onSubmit: (_) async => const TripMutationSucceeded(),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('open-dialog')));
        await tester.pumpAndSettle();

        expect(find.byType(TripFormDialog), findsOneWidget);

        final dropdowns = tester
            .widgetList<DropdownButton<String>>(
              find.byType(DropdownButton<String>),
            )
            .toList();

        expect(dropdowns, isNotEmpty);
        expect(dropdowns.every((dropdown) => dropdown.isExpanded), isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'trip form stays open on failure and closes after retry success',
      (tester) async {
        var submitCount = 0;

        await tester.pumpWidget(
          _dialogLauncher(
            builder: (_) => TripFormDialog(
              title: 'Edit trip',
              trip: _editableTrip,
              lookups: _lookups,
              financialConfiguration: null,
              onSubmit: (_) async {
                submitCount++;
                if (submitCount == 1) {
                  return const TripMutationFailed(
                    ValidationFailure(
                      code: FailureCodes.validationTripDeliveryBeforeLoading,
                    ),
                  );
                }
                return const TripMutationSucceeded();
              },
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('open-dialog')));
        await tester.pumpAndSettle();

        final saveLabel = AppLocalizationsEn().saveButton;
        await tester.tap(find.text(saveLabel));
        await tester.pumpAndSettle();

        expect(find.byType(TripFormDialog), findsOneWidget);
        expect(
          find.text(AppLocalizationsEn().tripDeliveryBeforeLoadingInvalid),
          findsOneWidget,
        );
        expect(submitCount, 1);

        await tester.tap(find.text(saveLabel));
        await tester.pumpAndSettle();

        expect(submitCount, 2);
        expect(find.byType(TripFormDialog), findsNothing);
      },
    );

    testWidgets(
      'live Route lookups update an open Trip form without clearing typed freight',
      (tester) async {
        final lookups = ValueNotifier<TripFormLookups>(_lookups);
        addTearDown(lookups.dispose);

        await tester.pumpWidget(
          _dialogLauncher(
            builder: (_) => ValueListenableBuilder<TripFormLookups>(
              valueListenable: lookups,
              builder: (_, available, _) => TripFormDialog(
                title: 'Edit trip',
                trip: _editableTrip,
                lookups: available,
                financialConfiguration: CurrencyConfiguration.tryCreate(
                  currencyCode: 'AED',
                  fractionDigits: 2,
                ),
                onSubmit: (_) async => const TripMutationSucceeded(),
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(const Key('open-dialog')));
        await tester.pumpAndSettle();

        final freightField = find.byType(TextFormField).at(3);
        await tester.ensureVisible(freightField);
        await tester.enterText(freightField, '123.45');
        await tester.pump();

        // Simulate both a new Route and a remote default-rate update.
        lookups.value = _realtimeLookups;
        await tester.pumpAndSettle();

        final routeField = tester.widget<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>).at(1),
        );
        expect(routeField.items!.map((item) => item.value), [
          'route-1',
          'route-2',
        ]);
        expect(
          tester.widget<TextFormField>(freightField).controller!.text,
          '123.45',
        );
        expect(find.byType(TripFormDialog), findsOneWidget);
      },
    );

    testWidgets(
      'remotely deactivated Route cannot be submitted from an open Trip form',
      (tester) async {
        final lookups = ValueNotifier<TripFormLookups>(_lookups);
        addTearDown(lookups.dispose);
        var submitCalls = 0;

        await tester.pumpWidget(
          _dialogLauncher(
            builder: (_) => ValueListenableBuilder<TripFormLookups>(
              valueListenable: lookups,
              builder: (_, available, _) => TripFormDialog(
                title: 'Edit trip',
                trip: _editableTrip,
                lookups: available,
                financialConfiguration: null,
                onSubmit: (_) async {
                  submitCalls++;
                  return const TripMutationSucceeded();
                },
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(const Key('open-dialog')));
        await tester.pumpAndSettle();

        // The selected route-1 disappears from authoritative active lookups.
        lookups.value = _lookupsWithoutSelectedRoute;
        await tester.pumpAndSettle();

        final routeField = tester.widget<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>).at(1),
        );
        expect(routeField.items!.map((item) => item.value), ['route-2']);

        await tester.tap(find.text(AppLocalizationsEn().saveButton));
        await tester.pumpAndSettle();

        expect(submitCalls, 0);
        expect(find.byType(TripFormDialog), findsOneWidget);
      },
    );

    testWidgets('status dialog blocks duplicate submit while pending', (
      tester,
    ) async {
      var submitCount = 0;
      final completion = Completer<TripMutationResult>();

      await tester.pumpWidget(
        _dialogLauncher(
          builder: (_) => TripStatusUpdateDialog(
            trip: _editableTrip,
            onSubmit: (_, _) {
              submitCount++;
              return completion.future;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open-dialog')));
      await tester.pumpAndSettle();

      final saveLabel = AppLocalizationsEn().saveButton;
      await tester.tap(find.text(saveLabel));
      await tester.pump();

      expect(submitCount, 1);

      final pendingButton = find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(FilledButton),
      );
      expect(pendingButton, findsOneWidget);
      expect(tester.widget<FilledButton>(pendingButton).onPressed, isNull);

      await tester.tap(pendingButton);
      await tester.pump();

      expect(submitCount, 1);
      expect(find.byType(TripStatusUpdateDialog), findsOneWidget);

      completion.complete(const TripMutationSucceeded());
      await tester.pumpAndSettle();

      expect(find.byType(TripStatusUpdateDialog), findsNothing);
    });
  });
}

final _editableTrip = TripEntity(
  id: 'trip-1',
  companyId: 'company-1',
  tripNumber: TripNumber.tryParse('TRP-2026-000001')!,
  customerId: 'customer-1',
  routeId: 'route-1',
  status: TripStatus.created,
);

const _lookups = TripFormLookups(
  customers: [TripLookupOption(id: 'customer-1', label: 'Customer One')],
  routes: [TripRouteLookupOption(id: 'route-1', label: 'Dubai -> Abu Dhabi')],
  drivers: [],
  tractorHeads: [],
  trailers: [],
);

final _realtimeLookups = TripFormLookups(
  customers: const [TripLookupOption(id: 'customer-1', label: 'Customer One')],
  routes: [
    TripRouteLookupOption(
      id: 'route-1',
      label: 'Dubai -> Abu Dhabi (updated)',
      defaultFreightRatePerTon: Money(
        minorUnits: 20000,
        currency: CurrencyConfiguration.tryCreate(
          currencyCode: 'AED',
          fractionDigits: 2,
        )!.currency,
      ),
    ),
    const TripRouteLookupOption(
      id: 'route-2',
      label: 'Jebel Ali -> Sharjah',
    ),
  ],
  drivers: const [],
  tractorHeads: const [],
  trailers: const [],
);

const _lookupsWithoutSelectedRoute = TripFormLookups(
  customers: [TripLookupOption(id: 'customer-1', label: 'Customer One')],
  routes: [TripRouteLookupOption(id: 'route-2', label: 'Jebel Ali -> Sharjah')],
  drivers: [],
  tractorHeads: [],
  trailers: [],
);

final _longLabelTrip = TripEntity(
  id: 'trip-long',
  companyId: 'company-1',
  tripNumber: TripNumber.tryParse('TRP-2026-000002')!,
  customerId: 'customer-long',
  routeId: 'route-long',
  status: TripStatus.created,
);

const _longLabelLookups = TripFormLookups(
  customers: [
    TripLookupOption(
      id: 'customer-long',
      label: 'Al Noor Heavy Transport Logistics International LLC',
    ),
  ],
  routes: [
    TripRouteLookupOption(
      id: 'route-long',
      label:
          'Jebel Ali Port -> Dubai South Logistics District Extended Route Name',
    ),
  ],
  drivers: [],
  tractorHeads: [],
  trailers: [],
);

Widget _localizedApp(Widget home, {Locale? locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

Widget _dialogLauncher({required WidgetBuilder builder, Locale? locale}) {
  return _localizedApp(
    Scaffold(
      body: Builder(
        builder: (context) => FilledButton(
          key: const Key('open-dialog'),
          onPressed: () => showDialog<void>(context: context, builder: builder),
          child: const Text('Open'),
        ),
      ),
    ),
    locale: locale,
  );
}
