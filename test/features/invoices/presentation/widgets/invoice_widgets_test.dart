import 'package:flutter/material.dart';
import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/widgets/app_form_failure_notice.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/invoices/domain/entities/billable_trip.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_customer_snapshot.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_totals.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_trip_line.dart';
import 'package:horus_system/features/invoices/domain/services/invoice_totals_calculator.dart';
import 'package:horus_system/features/invoices/domain/value_objects/tax_rate.dart';
import 'package:horus_system/features/invoices/presentation/cubit/invoice_details_state.dart';
import 'package:horus_system/features/invoices/presentation/cubit/invoice_draft_form_input.dart';
import 'package:horus_system/features/invoices/presentation/widgets/invoice_details_dialog.dart';
import 'package:horus_system/features/invoices/presentation/widgets/invoice_draft_dialog.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/subscriptions/domain/failures/quota_failure_codes.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'grouped invoice draft selects multiple readable Trips without UUID leakage',
    (tester) async {
      const firstTripId = '771d829f-fd6e-46cd-bb30-e6ee8cc3a56f';
      const secondTripId = '60f366ef-cb31-4e48-b249-a7d774f615bc';
      InvoiceDraftFormInput? submittedInput;
      final trips = [
        _billableTrip(id: firstTripId, tripNumber: 'TRP-2026-000001'),
        _billableTrip(id: secondTripId, tripNumber: 'TRP-2026-000002'),
      ];

      await _pumpLocalized(
        tester,
        child: InvoiceDraftDialog(
          billableTrips: trips,
          currencyFractionDigits: 2,
          onCalculatePreview: ({required customerId, required trips}) async {
            return _previewFor(trips);
          },
          onSubmit: (input) async {
            submittedInput = input;
            return false;
          },
        ),
      );

      await tester.tap(find.byKey(const ValueKey('invoiceDraftCustomerField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customer One').last);
      await tester.pumpAndSettle();

      expect(find.textContaining(firstTripId), findsNothing);
      expect(find.textContaining(secondTripId), findsNothing);
      expect(find.textContaining('TRP-2026-000001'), findsOneWidget);
      expect(find.textContaining('TRP-2026-000002'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('invoiceDraftTrip-$firstTripId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('invoiceDraftTrip-$secondTripId')),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey('invoiceDraftSaveButton')),
      );
      await tester.tap(find.byKey(const ValueKey('invoiceDraftSaveButton')));
      await tester.pumpAndSettle();

      expect(submittedInput, isNotNull);
      expect(submittedInput!.customerId, 'customer-1');
      expect(
        submittedInput!.tripIds,
        containsAll(<String>[firstTripId, secondTripId]),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'lifetime quota rejection stays in invoice dialog and preserves draft',
    (tester) async {
      final trips = [
        _billableTrip(id: 'trip-quota', tripNumber: 'TRP-2026-000030'),
      ];
      await _pumpLocalized(
        tester,
        child: InvoiceDraftDialog(
          billableTrips: trips,
          currencyFractionDigits: 2,
          onCalculatePreview: ({required customerId, required trips}) async {
            return _previewFor(trips);
          },
          onSubmit: (_) async => false,
          getSubmitFailure: () => const ConflictFailure(
            code: QuotaFailureCodes.lifetimeInvoicesReached,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('invoiceDraftCustomerField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customer One').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('invoiceDraftTrip-trip-quota')),
      );
      await tester.pumpAndSettle();

      final notes = find.byType(TextFormField).last;
      await tester.enterText(notes, 'Keep invoice draft');
      final save = find.byKey(const ValueKey('invoiceDraftSaveButton'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.byType(InvoiceDraftDialog), findsOneWidget);
      expect(find.byType(AppFormFailureNotice), findsOneWidget);
      expect(
        find.textContaining('lifetime invoice creation limit'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextFormField>(notes).controller!.text,
        'Keep invoice draft',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Arabic lifetime invoice quota denial is visible on narrow RTL layout',
    (tester) async {
      await _setSurfaceSize(tester, const Size(390, 844));
      final trips = [
        _billableTrip(id: 'trip-quota-ar', tripNumber: 'TRP-2026-000030'),
      ];
      await _pumpLocalized(
        tester,
        locale: const Locale('ar'),
        child: InvoiceDraftDialog(
          billableTrips: trips,
          currencyFractionDigits: 2,
          onCalculatePreview: ({required customerId, required trips}) async {
            return _previewFor(trips);
          },
          onSubmit: (_) async => false,
          getSubmitFailure: () => const ConflictFailure(
            code: QuotaFailureCodes.lifetimeInvoicesReached,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('invoiceDraftCustomerField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customer One').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('invoiceDraftTrip-trip-quota-ar')),
      );
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('invoiceDraftSaveButton'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final notice = find.byType(AppFormFailureNotice);
      expect(notice, findsOneWidget);
      expect(
        find.textContaining('الحد الإجمالي لإنشاء الفواتير'),
        findsOneWidget,
      );
      expect(Directionality.of(tester.element(notice)), TextDirection.rtl);
      expect(find.byType(InvoiceDraftDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'grouped invoice draft stays responsive in Arabic at narrow width',
    (tester) async {
      await _setSurfaceSize(tester, const Size(390, 844));
      final trips = [
        _billableTrip(id: 'trip-1', tripNumber: 'TRP-2026-000001'),
        _billableTrip(id: 'trip-2', tripNumber: 'TRP-2026-000002'),
      ];

      await _pumpLocalized(
        tester,
        locale: const Locale('ar'),
        child: InvoiceDraftDialog(
          billableTrips: trips,
          currencyFractionDigits: 2,
          onCalculatePreview: ({required customerId, required trips}) async {
            return _previewFor(trips);
          },
          onSubmit: (_) async => false,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('invoiceDraftCustomerField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customer One').last);
      await tester.pumpAndSettle();

      expect(find.text('الرحلات القابلة للفوترة'), findsOneWidget);
      expect(find.textContaining('TRP-2026-000001'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invoice details use the app details Dialog pattern and hide raw UUID',
    (tester) async {
      const tripId = '771d829f-fd6e-46cd-bb30-e6ee8cc3a56f';
      await _setSurfaceSize(tester, const Size(390, 844));
      await _pumpLocalized(
        tester,
        child: InvoiceDetailsDialog(
          state: _loadedState(tripId: tripId),
          onRetry: () {},
          onIssue: (_, _) async => false,
          onCancel: (_, _) async => false,
        ),
      );

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.byKey(const ValueKey('invoiceDialogCloseButton')),
        findsOneWidget,
      );
      expect(find.textContaining(tripId), findsNothing);
      expect(find.textContaining('DUBAI → SHARJAH'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('issue flow stays inside one app details Dialog', (tester) async {
    await _setSurfaceSize(tester, const Size(390, 844));
    await _pumpLocalized(
      tester,
      child: InvoiceDetailsDialog(
        state: _loadedState(),
        onRetry: () {},
        onIssue: (_, _) async => false,
        onCancel: (_, _) async => false,
      ),
    );

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    final issueButton = find.byKey(const ValueKey('invoiceIssueActionButton'));
    await tester.ensureVisible(issueButton);
    await tester.pumpAndSettle();
    await tester.tap(issueButton);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.byKey(const ValueKey('invoiceIssueSubmitButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('invoiceDialogCloseButton')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel flow stays inside one app details Dialog', (
    tester,
  ) async {
    await _setSurfaceSize(tester, const Size(390, 844));
    await _pumpLocalized(
      tester,
      child: InvoiceDetailsDialog(
        state: _loadedState(),
        onRetry: () {},
        onIssue: (_, _) async => false,
        onCancel: (_, _) async => false,
      ),
    );

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    final cancelButton = find.byKey(
      const ValueKey('invoiceCancelActionButton'),
    );
    await tester.ensureVisible(cancelButton);
    await tester.pumpAndSettle();
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.byKey(const ValueKey('invoiceCancelSubmitButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('invoiceDialogCloseButton')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

final CurrencyCode _currency = CurrencyCode.tryParse('AED')!;
final TaxRate _zeroTax = TaxRate.tryCreate(0)!;

BillableTrip _billableTrip({required String id, String? tripNumber}) {
  return BillableTrip(
    id: id,
    companyId: 'company-1',
    customerId: 'customer-1',
    status: TripStatus.documentsReceived,
    freightAmount: Money(minorUnits: 12000000, currency: _currency),
    isAlreadyInvoiced: false,
    tripNumber: tripNumber,
    customerName: 'Customer One',
    loadingLocation: 'DUBAI',
    unloadingLocation: 'SHARJAH',
    serviceDate: BusinessDate(year: 2026, month: 6, day: 20),
  );
}

InvoiceTotals _previewFor(List<BillableTrip> trips) {
  final result = const InvoiceTotalsCalculator().calculate(
    lineAmounts: trips
        .map((trip) => trip.freightAmount)
        .toList(growable: false),
    currency: _currency,
    discountMinorUnits: 0,
    taxRateBasisPoints: 0,
  );
  return result.dataOrNull!;
}

InvoiceDetailsLoaded _loadedState({String tripId = 'trip-1'}) {
  final trip = _billableTrip(id: tripId);
  final line = InvoiceTripLine.fromBillableTrip(trip);
  final zero = Money(minorUnits: 0, currency: _currency);
  return InvoiceDetailsLoaded(
    invoiceCreatedAt: BusinessLocalDateTime(
      year: 2026,
      month: 8,
      day: 7,
      hour: 4,
      minute: 0,
    ),
    currentCompanyContext: const CurrentCompanyContext(
      company: Company(
        id: 'company-1',
        name: 'Test Company',
        baseCurrencyCode: 'AED',
        baseCurrencyFractionDigits: 2,
        businessTimezone: 'Asia/Dubai',
      ),
      role: CompanyRole.accountant,
    ),
    invoice: Invoice(
      id: 'invoice-1',
      companyId: 'company-1',
      customer: const InvoiceCustomerSnapshot(
        companyId: 'company-1',
        customerId: 'customer-1',
        name: 'Customer One',
      ),
      status: InvoiceStatus.draft,
      currency: _currency,
      lines: [line],
      totals: InvoiceTotals(
        subtotal: line.amount,
        discount: zero,
        taxableAmount: line.amount,
        taxRate: _zeroTax,
        taxAmount: zero,
        grandTotal: line.amount,
      ),
      createdAt: DateTime.utc(2026, 8, 7),
      updatedAt: DateTime.utc(2026, 8, 7),
    ),
  );
}

Future<void> _setSurfaceSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

Future<void> _pumpLocalized(
  WidgetTester tester, {
  required Widget child,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}
