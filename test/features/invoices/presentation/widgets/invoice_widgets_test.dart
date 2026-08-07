import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:horus_system/features/invoices/domain/value_objects/tax_rate.dart';
import 'package:horus_system/features/invoices/presentation/cubit/invoice_details_state.dart';
import 'package:horus_system/features/invoices/presentation/widgets/invoice_details_dialog.dart';
import 'package:horus_system/features/invoices/presentation/widgets/invoice_draft_dialog.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('billable trip dropdown never exposes the raw trip UUID', (
    tester,
  ) async {
    const tripId = '771d829f-fd6e-46cd-bb30-e6ee8cc3a56f';
    await _pumpLocalized(
      tester,
      child: InvoiceDraftDialog(
        billableTrips: [_billableTrip(id: tripId)],
        currencyFractionDigits: 2,
        onSubmit: (_) async => false,
      ),
    );

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('invoiceDraftTripField')));
    await tester.pumpAndSettle();

    expect(find.textContaining(tripId), findsNothing);
    expect(find.textContaining('Customer One'), findsOneWidget);
    expect(find.textContaining('DUBAI → SHARJAH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invoice details use the standard AlertDialog and hide raw UUID', (
    tester,
  ) async {
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

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining(tripId), findsNothing);
    expect(find.textContaining('DUBAI → SHARJAH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('issue flow stays inside one standard AlertDialog', (tester) async {
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

    expect(find.byType(AlertDialog), findsOneWidget);

    final issueButton = find.byKey(const ValueKey('invoiceIssueActionButton'));
    await tester.ensureVisible(issueButton);
    await tester.pumpAndSettle();
    await tester.tap(issueButton);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Issue invoice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel flow stays inside one standard AlertDialog', (
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

    expect(find.byType(AlertDialog), findsOneWidget);

    final cancelButton = find.byKey(
      const ValueKey('invoiceCancelActionButton'),
    );
    await tester.ensureVisible(cancelButton);
    await tester.pumpAndSettle();
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Cancel invoice'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

final CurrencyCode _currency = CurrencyCode.tryParse('AED')!;
final TaxRate _zeroTax = TaxRate.tryCreate(0)!;

BillableTrip _billableTrip({required String id}) {
  return BillableTrip(
    id: id,
    companyId: 'company-1',
    customerId: 'customer-1',
    status: TripStatus.documentsReceived,
    freightAmount: Money(minorUnits: 12000000, currency: _currency),
    isAlreadyInvoiced: false,
    customerName: 'Customer One',
    loadingLocation: 'DUBAI',
    unloadingLocation: 'SHARJAH',
    serviceDate: DateTime.utc(2026, 6, 20),
  );
}

InvoiceDetailsLoaded _loadedState({String tripId = 'trip-1'}) {
  final trip = _billableTrip(id: tripId);
  final line = InvoiceTripLine.fromBillableTrip(trip);
  final zero = Money(minorUnits: 0, currency: _currency);
  return InvoiceDetailsLoaded(
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
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}
