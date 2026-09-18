import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_form_lookups.dart';
import 'package:horus_system/features/trips/domain/entities/trip_lookup_option.dart';
import 'package:horus_system/features/trips/domain/entities/trip_route_lookup_option.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
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
            .widgetList<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .toList();

        expect(dropdowns, isNotEmpty);
        expect(dropdowns.every((dropdown) => dropdown.isExpanded), isTrue);
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

const _editableTrip = TripEntity(
  id: 'trip-1',
  companyId: 'company-1',
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

const _longLabelTrip = TripEntity(
  id: 'trip-long',
  companyId: 'company-1',
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

Widget _dialogLauncher({
  required WidgetBuilder builder,
  Locale? locale,
}) {
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
